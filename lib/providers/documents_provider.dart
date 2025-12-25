import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/cv_data.dart';
import '../models/cover_letter.dart';
import '../models/template_style.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';

/// Provider for managing CVs and Cover Letters
class DocumentsProvider extends ChangeNotifier {
  final StorageService _storage = StorageService.instance;
  final PdfService _pdfService = PdfService.instance;
  final Uuid _uuid = const Uuid();

  List<CvData> _cvs = [];
  List<CoverLetter> _coverLetters = [];
  bool _isLoading = false;
  String? _error;

  // PDF generation state
  bool _isGeneratingPdf = false;
  Uint8List? _lastGeneratedPdf;

  List<CvData> get cvs => _cvs;
  List<CoverLetter> get coverLetters => _coverLetters;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isGeneratingPdf => _isGeneratingPdf;
  Uint8List? get lastGeneratedPdf => _lastGeneratedPdf;

  /// Load all documents from storage
  Future<void> loadDocuments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cvs = await _storage.loadCvs();
      _coverLetters = await _storage.loadCoverLetters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load documents: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================================
  // CV OPERATIONS
  // ============================================================================

  /// Create a new CV
  Future<CvData> createCv({
    required String name,
    String? profile,
    List<String>? skills,
    ContactDetails? contactDetails,
  }) async {
    final cv = CvData(
      id: _uuid.v4(),
      name: name,
      profile: profile ?? '',
      skills: skills ?? [],
      contactDetails: contactDetails,
      lastModified: DateTime.now(),
    );

    await _storage.saveCv(cv);
    _cvs.insert(0, cv);
    notifyListeners();

    return cv;
  }

  /// Update an existing CV
  Future<void> updateCv(CvData cv) async {
    final updated = cv.copyWith(lastModified: DateTime.now());
    await _storage.saveCv(updated);

    final index = _cvs.indexWhere((c) => c.id == cv.id);
    if (index != -1) {
      _cvs[index] = updated;
      notifyListeners();
    }
  }

  /// Delete a CV
  Future<void> deleteCv(String id) async {
    await _storage.deleteCv(id);
    _cvs.removeWhere((cv) => cv.id == id);
    notifyListeners();
  }

  /// Get CV by ID
  CvData? getCvById(String id) {
    try {
      return _cvs.firstWhere((cv) => cv.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Generate CV PDF
  Future<Uint8List> generateCvPdf(CvData cv, TemplateStyle style) async {
    _isGeneratingPdf = true;
    notifyListeners();

    try {
      final bytes = await _pdfService.generateCvPdf(cv, style);
      _lastGeneratedPdf = bytes;
      _isGeneratingPdf = false;
      notifyListeners();
      return bytes;
    } catch (e) {
      _isGeneratingPdf = false;
      _error = 'Failed to generate PDF: $e';
      notifyListeners();
      rethrow;
    }
  }

  // ============================================================================
  // COVER LETTER OPERATIONS
  // ============================================================================

  /// Create a new cover letter
  Future<CoverLetter> createCoverLetter({
    required String name,
    String? greeting,
    String? body,
    String? closing,
    String? senderName,
  }) async {
    final letter = CoverLetter(
      id: _uuid.v4(),
      name: name,
      greeting: greeting ?? 'Dear Hiring Manager,',
      body: body ?? '',
      closing: closing ?? 'Kind regards,',
      senderName: senderName,
      lastModified: DateTime.now(),
    );

    await _storage.saveCoverLetter(letter);
    _coverLetters.insert(0, letter);
    notifyListeners();

    return letter;
  }

  /// Update an existing cover letter
  Future<void> updateCoverLetter(CoverLetter letter) async {
    final updated = letter.copyWith(lastModified: DateTime.now());
    await _storage.saveCoverLetter(updated);

    final index = _coverLetters.indexWhere((l) => l.id == letter.id);
    if (index != -1) {
      _coverLetters[index] = updated;
      notifyListeners();
    }
  }

  /// Delete a cover letter
  Future<void> deleteCoverLetter(String id) async {
    await _storage.deleteCoverLetter(id);
    _coverLetters.removeWhere((letter) => letter.id == id);
    notifyListeners();
  }

  /// Get cover letter by ID
  CoverLetter? getCoverLetterById(String id) {
    try {
      return _coverLetters.firstWhere((letter) => letter.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Generate cover letter PDF
  Future<Uint8List> generateCoverLetterPdf(
    CoverLetter letter,
    TemplateStyle style, {
    String? senderAddress,
    String? senderPhone,
    String? senderEmail,
  }) async {
    _isGeneratingPdf = true;
    notifyListeners();

    try {
      final bytes = await _pdfService.generateCoverLetterPdf(
        letter,
        style,
        senderAddress: senderAddress,
        senderPhone: senderPhone,
        senderEmail: senderEmail,
      );
      _lastGeneratedPdf = bytes;
      _isGeneratingPdf = false;
      notifyListeners();
      return bytes;
    } catch (e) {
      _isGeneratingPdf = false;
      _error = 'Failed to generate PDF: $e';
      notifyListeners();
      rethrow;
    }
  }

  // ============================================================================
  // PDF UTILITIES
  // ============================================================================

  /// Print last generated PDF
  Future<bool> printLastPdf({String? documentName}) async {
    if (_lastGeneratedPdf == null) return false;
    return _pdfService.printPdf(_lastGeneratedPdf!, documentName: documentName);
  }

  /// Share last generated PDF
  Future<bool> shareLastPdf({String? filename}) async {
    if (_lastGeneratedPdf == null) return false;
    return _pdfService.sharePdf(_lastGeneratedPdf!, filename: filename);
  }

  /// Clear last generated PDF
  void clearLastPdf() {
    _lastGeneratedPdf = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
