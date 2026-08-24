class SyncBackendConfig {
  const SyncBackendConfig({required this.url, required this.publishableKey});

  static const defaultUrl = 'https://kblgnhbscexeeomvjrgt.supabase.co';
  static const defaultPublishableKey =
      'sb_publishable_egfNvE0Qe--3_y7JwMG9PQ_vO9IeA7_';

  factory SyncBackendConfig.fromEnvironment({
    bool useBundledDefaults = false,
  }) {
    const environmentUrl = String.fromEnvironment('SUPABASE_URL');
    const environmentKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    return SyncBackendConfig(
      url: environmentUrl.isEmpty && useBundledDefaults
          ? defaultUrl
          : environmentUrl,
      publishableKey: environmentKey.isEmpty && useBundledDefaults
          ? defaultPublishableKey
          : environmentKey,
    );
  }

  final String url;
  final String publishableKey;

  bool get isConfigured =>
      Uri.tryParse(url)?.hasScheme == true && publishableKey.trim().isNotEmpty;
}
