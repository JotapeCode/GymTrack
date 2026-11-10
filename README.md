# GymTrack

Aplicativo Android em Flutter/Dart para acompanhar a evolução de **cargas e repetições** na academia.
Funciona 100% offline: todos os dados ficam em um banco **SQLite** local no dispositivo.

## Credenciais iniciais

| Perfil         | E-mail                 | Senha        |
|----------------|------------------------|--------------|
| Administrador  | `admin@gymtrack.com`   | `admin123`   |
| Usuário comum  | `usuario@gymtrack.com` | `usuario123` |

Na primeira execução, o banco é criado com esses dois usuários e um histórico de demonstração
(Supino reto, Rosca direta, Tríceps pulley, Agachamento livre e Puxada alta, com cargas progressivas),
para que os gráficos e comparações já apareçam na apresentação.

## Funcionalidades

- **Login** com validação dos campos, mensagens de erro e opção de mostrar a senha.
- **Dois perfis**: o administrador tem acesso total e à aba *Usuários*. O usuário comum não acessa a área administrativa.
- **Dashboard**: saudação, total de exercícios e treinos, último treino, resumo da evolução de carga, botão *Registrar treino* e exercícios recentes.
- **Exercícios (aba Treinos)**: CRUD com nome, grupo muscular, descrição opcional e data, além de filtro por grupo muscular.
- **Registro de treino**: data, exercício, séries dinâmicas (repetições e carga em kg em cada série) e observações. Os valores do último treino vêm pré-preenchidos. É possível editar e excluir registros.
- **Histórico**: filtro por exercício e por período, volume total, comparação com o registro anterior (↑ / ↓ kg) e destaque de **RECORDE**.
- **Gráfico de evolução** (fl_chart) da carga máxima por treino, com os pontos de aumento de carga destacados.
- **Administração de usuários**: lista com nome, e-mail, tipo e status, criação, edição e exclusão (com confirmação), troca do tipo entre Administrador e Usuário comum e ativação/desativação da conta. O app impede excluir, rebaixar ou desativar o **último administrador ativo**.
- **Perfil**: dados da conta, edição do nome, troca de senha e saída da conta.

## Segurança

As senhas **nunca são salvas em texto puro**. Cada usuário tem um *salt* aleatório de 16 bytes, e a senha é derivada com
**PBKDF2-HMAC-SHA256 (10.000 iterações)**. A comparação é feita em tempo constante.

## Banco de dados (SQLite / sqflite)

```
users (id, name, email UNIQUE, password_hash, password_salt, role, is_active, created_at)
  └─< exercises (id, user_id FK, name, muscle_group, description, date)
        └─< workouts (id, user_id FK, exercise_id FK, date, notes)
              └─< workout_sets (id, workout_id FK, set_number, reps, weight)
```

As chaves estrangeiras usam `ON DELETE CASCADE`: excluir um exercício remove os treinos e as séries dele.

## Arquitetura

```
lib/
├── controllers/   # Estado com Provider (ChangeNotifier): Auth, Training, UserAdmin
├── database/      # AppDatabase (schema SQLite) e DatabaseSeeder (dados iniciais)
├── models/        # AppUser, Exercise, Workout/WorkoutSet, MuscleGroup
├── repositories/  # Acesso a dados: User, Exercise, Workout
├── screens/       # Telas (login, shell, dashboard, treinos, histórico, perfil, admin/)
├── services/      # PasswordService (hash PBKDF2)
├── theme/         # Paleta, espaçamentos e ThemeData dark
├── utils/         # Formatadores (pt-BR) e validadores
└── widgets/       # Componentes reutilizáveis (cards, gráfico, card de treino)
```

O fluxo segue **View → Controller (ChangeNotifier) → Repository → SQLite**. A fonte **Inter** vem embutida em
`assets/fonts`, então funciona sem internet.

## Como executar

Pré-requisitos: Flutter 3.38 ou superior (testado com o 3.47.5) e Android SDK com um emulador ou aparelho conectado.

```bash
flutter pub get
flutter run            # executa no emulador/dispositivo conectado
flutter analyze        # análise estática
flutter test           # testes unitários, de repositório e de widget
```

### Gerar o APK

```bash
flutter build apk --release
```

O APK é gerado em `build/app/outputs/flutter-apk/app-release.apk`. Para instalar no emulador ou no celular, use
`flutter install` ou arraste o arquivo para o emulador.

> Para reiniciar os dados de demonstração, desinstale o app (ou limpe os dados dele) e abra-o de novo.
