# Система аутентификации

## Структура

```
lib/core/auth/
├── models/
│   ├── auth_state.dart         # Состояния аутентификации (initial, authenticated, unauthenticated, loading)
│   ├── auth_tokens.dart        # Модель токенов (access, refresh, expiresAt)
│   └── user_model.dart         # Модель пользователя
├── services/
│   ├── auth_service.dart       # Сервис для работы с API аутентификации
│   └── token_storage.dart      # Безопасное хранение токенов
├── notifiers/
│   └── auth_notifier.dart      # Riverpod Notifier для управления состоянием
├── auth_di.dart                # Dependency Injection
└── auth.dart                   # Экспорт всех компонентов
```

## Основные компоненты

### 1. AuthTokens
Модель для хранения токенов авторизации:
- `accessToken` - токен доступа
- `refreshToken` - токен обновления
- `expiresAt` - время истечения токена
- `isExpired` - проверка истечения
- `isValid` - проверка валидности

### 2. UserModel
Модель пользователя:
- `id` - уникальный идентификатор
- `email` - email пользователя
- `name` - имя (опционально)
- `avatarUrl` - URL аватара (опционально)
- `isEmailVerified` - подтверждение email
- `createdAt` - дата создания

### 3. AuthState
Состояния аутентификации:
- `initial()` - начальное состояние
- `authenticated(UserModel user)` - пользователь авторизован
- `unauthenticated()` - пользователь не авторизован
- `loading()` - загрузка

### 4. TokenStorage
Безопасное хранение токенов с использованием `flutter_secure_storage`:
- `saveTokens(AuthTokens)` - сохранить токены
- `getTokens()` - получить токены
- `clearTokens()` - удалить токены
- `getAccessToken()` - получить access token
- `getRefreshToken()` - получить refresh token
- `hasTokens()` - проверить наличие токенов

### 5. AuthService
Сервис для работы с API:
- `signUp({email, password})` - регистрация
- `signIn({email, password})` - вход
- `signOut()` - выход
- `refreshToken()` - обновление токена
- `getCurrentUser()` - получить текущего пользователя
- `isAuthenticated()` - проверка авторизации

### 6. AuthNotifier
Управление состоянием аутентификации:
- `signUp({email, password})` - регистрация
- `signIn({email, password})` - вход
- `signOut()` - выход
- `refreshUser()` - обновить данные пользователя
- `currentUser` - текущий пользователь
- `isAuthenticated` - проверка авторизации

## Использование

### Настройка API URL

В файле `lib/core/auth/auth_di.dart` укажите URL вашего API:

```dart
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://your-api-url.com/api', // ← Замените на ваш URL
      ...
    ),
  );
  ...
});
```

### Регистрация

```dart
final authNotifier = ref.read(authNotifierProvider.notifier);

try {
  await authNotifier.signUp(
    email: 'user@example.com',
    password: 'SecurePassword123!',
  );
  // Успешная регистрация
} on AuthException catch (e) {
  // Обработка ошибки
  print(e.message);
}
```

### Вход

```dart
final authNotifier = ref.read(authNotifierProvider.notifier);

try {
  await authNotifier.signIn(
    email: 'user@example.com',
    password: 'SecurePassword123!',
  );
  // Успешный вход
} on AuthException catch (e) {
  // Обработка ошибки
  print(e.message);
}
```

### Выход

```dart
final authNotifier = ref.read(authNotifierProvider.notifier);
await authNotifier.signOut();
```

### Проверка состояния

```dart
// В виджете
Widget build(BuildContext context, WidgetRef ref) {
  final authState = ref.watch(authNotifierProvider);
  
  return authState.when(
    initial: () => LoadingScreen(),
    loading: () => LoadingScreen(),
    authenticated: (user) => HomeScreen(user: user),
    unauthenticated: () => LoginScreen(),
  );
}
```

### Получение текущего пользователя

```dart
final authNotifier = ref.read(authNotifierProvider.notifier);
final user = authNotifier.currentUser; // UserModel?
```

### Проверка авторизации

```dart
final authNotifier = ref.read(authNotifierProvider.notifier);
final isAuth = authNotifier.isAuthenticated; // bool
```

## Автоматическое обновление токенов

Система автоматически обновляет токены при получении ошибки 401 благодаря `AuthInterceptor`:
1. При 401 ошибке пытается обновить токен через `refreshToken()`
2. Повторяет оригинальный запрос с новым токеном
3. Если обновление не удалось, выполняет logout

## Формат API ответов

### SignUp/SignIn Response
```json
{
  "user": {
    "id": "user-id",
    "email": "user@example.com",
    "name": "User Name",
    "avatarUrl": "https://...",
    "isEmailVerified": false,
    "createdAt": "2025-01-01T00:00:00Z"
  },
  "tokens": {
    "accessToken": "jwt-token",
    "refreshToken": "refresh-token",
    "expiresAt": "2025-01-02T00:00:00Z"
  }
}
```

### Refresh Token Response
```json
{
  "accessToken": "new-jwt-token",
  "refreshToken": "new-refresh-token",
  "expiresAt": "2025-01-02T00:00:00Z"
}
```

### Get Current User Response
```json
{
  "id": "user-id",
  "email": "user@example.com",
  "name": "User Name",
  "avatarUrl": "https://...",
  "isEmailVerified": true,
  "createdAt": "2025-01-01T00:00:00Z"
}
```

## Обработка ошибок

Все методы `AuthService` бросают `AuthException` с понятным сообщением:

```dart
try {
  await authService.signIn(email: email, password: password);
} on AuthException catch (e) {
  // e.message - текст ошибки на русском
  // e.statusCode - HTTP статус код (опционально)
  showError(e.message);
}
```

## Безопасность

- Токены хранятся в `flutter_secure_storage` (зашифрованное хранилище)
- На Android используется `EncryptedSharedPreferences`
- Access token автоматически добавляется к каждому запросу
- Автоматическое обновление истекших токенов
- Автоматический logout при невалидном refresh token
