const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api',
);

const useApiRepositories = bool.fromEnvironment('USE_API', defaultValue: true);

const useSupabaseBackend = bool.fromEnvironment(
  'USE_SUPABASE',
  defaultValue: false,
);

const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: '',
);

const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: '',
);
