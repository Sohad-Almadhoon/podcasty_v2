import 'api_client.dart';

/// Model for AI generation result
class GenerationResult {
  final String audioUrl;
  final String imageUrl;
  
  GenerationResult({
    required this.audioUrl,
    required this.imageUrl,
  });
  
  factory GenerationResult.fromJson(Map<String, dynamic> json) {
    return GenerationResult(
      audioUrl: json['audio_url'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }
}

/// Service for AI content generation API operations
class GenerationService {
  /// Generate podcast audio and cover image using AI
  /// 
  /// [prompt] - Text prompt for content generation
  /// [voice] - Voice type (optional)
  /// [style] - Audio style (optional)
  static Future<GenerationResult> generatePodcastContent({
    required String prompt,
    String? voice,
    String? style,
  }) async {
    final data = await ApiClient.request(
      endpoint: '/api/generate',
      method: 'POST',
      body: {
        'prompt': prompt,
        if (voice != null) 'voice': voice,
        if (style != null) 'style': style,
      },
    );
    
    return GenerationResult.fromJson(data);
  }
}
