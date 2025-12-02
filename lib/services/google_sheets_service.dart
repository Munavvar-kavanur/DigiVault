import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/password_entry.dart';

class GoogleSheetsService {
  String? _webAppUrl;

  void setUrl(String url) {
    _webAppUrl = url;
    if (!url.endsWith('/exec')) {
      print('Warning: Web App URL usually ends with /exec');
    }
  }

  bool get isConfigured => _webAppUrl != null && _webAppUrl!.isNotEmpty;
  String? get webAppUrl => _webAppUrl;

  Future<Map<String, dynamic>> testConnection(String url) async {
    try {
      final response = await http.get(Uri.parse('$url?action=test'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check for version
        String version = '1.0';
        try {
          final versionResponse = await http.get(
            Uri.parse('$url?action=version'),
          );
          if (versionResponse.statusCode == 200) {
            final vData = jsonDecode(versionResponse.body);
            if (vData['status'] == 'success') {
              version = vData['version'] ?? '1.0';
            }
          }
        } catch (e) {
          print('Version check failed: $e');
        }

        return {
          'success': data['status'] == 'success',
          'version': version,
          'message': data['status'] == 'success' ? 'Connected' : 'Failed',
        };
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      print('Connection test failed: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> openSheet() async {
    if (!isConfigured) return;

    try {
      final response = await http.get(
        Uri.parse('$_webAppUrl?action=getSpreadsheetUrl'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['url'] != null) {
          final Uri uri = Uri.parse(data['url']);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return;
          }
        }
      }
    } catch (e) {
      print('Error getting sheet URL: $e');
    }

    // Fallback
    final Uri uri = Uri.parse(_webAppUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<List<PasswordEntry>> fetchAll() async {
    if (!isConfigured) return [];

    try {
      final response = await http.get(Uri.parse('$_webAppUrl?action=readAll'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> entriesJson = data['data'];
          return entriesJson
              .map((json) => PasswordEntry.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching from Sheets: $e');
      return [];
    }
  }

  Future<List<String>> fetchCategories() async {
    if (!isConfigured) return [];

    try {
      final response = await http.get(
        Uri.parse('$_webAppUrl?action=readCategories'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return List<String>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching categories from Sheets: $e');
      return [];
    }
  }

  Future<bool> syncEntry(PasswordEntry entry) async {
    if (!isConfigured) return false;

    try {
      // We use text/plain to avoid CORS preflight (OPTIONS) requests on Web
      final response = await http.post(
        Uri.parse(_webAppUrl!),
        headers: {'Content-Type': 'text/plain'},
        body: jsonEncode({'action': 'syncEntry', 'data': entry.toJson()}),
      );

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final data = jsonDecode(response.body);
          return data['status'] == 'success';
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error syncing entry to Sheets: $e');
      return false;
    }
  }

  Future<bool> deleteEntry(String id) async {
    if (!isConfigured) return false;

    try {
      final response = await http.post(
        Uri.parse(_webAppUrl!),
        headers: {'Content-Type': 'text/plain'},
        body: jsonEncode({'action': 'deleteEntry', 'id': id}),
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting entry from Sheets: $e');
      return false;
    }
  }

  Future<bool> syncCategories(List<String> categories) async {
    if (!isConfigured) return false;

    try {
      final response = await http.post(
        Uri.parse(_webAppUrl!),
        headers: {'Content-Type': 'text/plain'},
        body: jsonEncode({'action': 'syncCategories', 'data': categories}),
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error syncing categories to Sheets: $e');
      return false;
    }
  }

  static const String scriptCode = r'''
function doGet(e) {
  const action = e.parameter.action;
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  
  if (action === 'test') {
    return ContentService.createTextOutput(JSON.stringify({status: 'success', message: 'Connection successful'})).setMimeType(ContentService.MimeType.JSON);
  }

  if (action === 'version') {
    return ContentService.createTextOutput(JSON.stringify({status: 'success', version: '2.0'})).setMimeType(ContentService.MimeType.JSON);
  }
  
  if (action === 'getSpreadsheetUrl') {
    return ContentService.createTextOutput(JSON.stringify({status: 'success', url: ss.getUrl()})).setMimeType(ContentService.MimeType.JSON);
  }
  
  if (action === 'readAll') {
    const sheet = ss.getSheetByName('Passwords');
    if (!sheet) return ContentService.createTextOutput(JSON.stringify({status: 'success', data: []})).setMimeType(ContentService.MimeType.JSON);
    
    const data = sheet.getDataRange().getValues();
    if (data.length < 2) return ContentService.createTextOutput(JSON.stringify({status: 'success', data: []})).setMimeType(ContentService.MimeType.JSON);
    
    const headers = data[0];
    const rows = data.slice(1);
    
    const entries = rows.map(row => {
      let entry = {};
      headers.forEach((header, index) => {
        entry[header] = row[index];
      });
      return entry;
    });
    
    return ContentService.createTextOutput(JSON.stringify({status: 'success', data: entries})).setMimeType(ContentService.MimeType.JSON);
  }
  
  if (action === 'readCategories') {
    const sheet = ss.getSheetByName('Categories');
    if (!sheet) return ContentService.createTextOutput(JSON.stringify({status: 'success', data: []})).setMimeType(ContentService.MimeType.JSON);
    
    const data = sheet.getDataRange().getValues();
    if (data.length < 2) return ContentService.createTextOutput(JSON.stringify({status: 'success', data: []})).setMimeType(ContentService.MimeType.JSON);
    
    // Assuming categories are in the first column
    const categories = data.slice(1).map(row => row[0]).filter(c => c !== '');
    return ContentService.createTextOutput(JSON.stringify({status: 'success', data: categories})).setMimeType(ContentService.MimeType.JSON);
  }
}

function doPost(e) {
  // Lock to prevent concurrent edits
  const lock = LockService.getScriptLock();
  lock.tryLock(10000);
  
  try {
    const request = JSON.parse(e.postData.contents);
    const action = request.action;
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    
    if (action === 'syncEntry') {
      let sheet = ss.getSheetByName('Passwords');
      if (!sheet) {
        sheet = ss.insertSheet('Passwords');
        sheet.appendRow(['id', 'title', 'username', 'password', 'website', 'category', 'notes', 'lastModified']);
      }
      
      const entry = request.data;
      const data = sheet.getDataRange().getValues();
      const headers = data[0];
      const idIndex = headers.indexOf('id');
      
      // Construct row data based on headers to ensure order
      const rowData = headers.map(header => {
        if (header === 'lastModified') return new Date().toISOString();
        return entry[header] || '';
      });
      
      let rowIndex = -1;
      if (data.length > 1) {
        for (let i = 1; i < data.length; i++) {
          if (data[i][idIndex] === entry.id) {
            rowIndex = i + 1;
            break;
          }
        }
      }
      
      if (rowIndex > 0) {
        // Update existing
        sheet.getRange(rowIndex, 1, 1, rowData.length).setValues([rowData]);
      } else {
        // Append new
        sheet.appendRow(rowData);
      }
      
      return ContentService.createTextOutput(JSON.stringify({status: 'success'})).setMimeType(ContentService.MimeType.JSON);
    }
    
    if (action === 'deleteEntry') {
      const sheet = ss.getSheetByName('Passwords');
      if (!sheet) return ContentService.createTextOutput(JSON.stringify({status: 'error'})).setMimeType(ContentService.MimeType.JSON);
      
      const id = request.id;
      const data = sheet.getDataRange().getValues();
      const idIndex = data[0].indexOf('id');
      
      for (let i = 1; i < data.length; i++) {
        if (data[i][idIndex] === id) {
          sheet.deleteRow(i + 1);
          break;
        }
      }
      
      return ContentService.createTextOutput(JSON.stringify({status: 'success'})).setMimeType(ContentService.MimeType.JSON);
    }

    if (action === 'syncCategories') {
      let sheet = ss.getSheetByName('Categories');
      if (!sheet) {
        sheet = ss.insertSheet('Categories');
        sheet.appendRow(['name']);
      }
      
      // Clear existing and replace
      const categories = request.data;
      const lastRow = sheet.getLastRow();
      if (lastRow > 1) {
        sheet.getRange(2, 1, lastRow - 1, 1).clearContent();
      }
      
      if (categories.length > 0) {
         const rows = categories.map(c => [c]);
         sheet.getRange(2, 1, rows.length, 1).setValues(rows);
      }
      
      return ContentService.createTextOutput(JSON.stringify({status: 'success'})).setMimeType(ContentService.MimeType.JSON);
    }
  } catch (e) {
    return ContentService.createTextOutput(JSON.stringify({status: 'error', message: e.toString()})).setMimeType(ContentService.MimeType.JSON);
  } finally {
    lock.releaseLock();
  }
}
''';
}
