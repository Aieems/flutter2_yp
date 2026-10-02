
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api',
);


const useApiRepositories = bool.fromEnvironment(
  'USE_API',
  defaultValue: true,
);
