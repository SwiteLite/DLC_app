# Drift — guide rapide pour DLC App

Drift est une librairie Flutter/Dart qui te permet d’utiliser une **base SQLite locale** avec du code Dart **typé**, sans écrire le SQL à la main (sauf si tu veux).

Dans cette app, Drift remplace l’ancien stockage SharedPreferences (un gros JSON).

---

## L’idée en une phrase

Tu décris tes **tables** en Dart → Drift génère le code → tu fais des requêtes typées → les données sont stockées dans un fichier SQLite sur le téléphone.

---

## Les 3 couches (dans ce projet)

```
UI (main.dart)
    ↓
FoodProvider  ← logique métier / filtres / notifications
    ↓
AppDatabase (Drift)  ← lecture / écriture SQLite
    ↓
Fichier local "dlc_app" (SQLite)
```

- **`Food`** (`lib/food.dart`) : modèle métier utilisé par l’UI
- **`FoodRow`** : ligne SQL générée par Drift
- **`AppDatabase`** (`lib/database/app_database.dart`) : pont entre les deux

---

## Fichiers importants

| Fichier | Rôle |
|---|---|
| `lib/database/app_database.dart` | Schéma + requêtes que **tu** écris |
| `lib/database/app_database.g.dart` | Code **généré** (ne pas éditer à la main) |
| `lib/food_provider.dart` | Appelle la BDD, garde la liste en mémoire pour l’UI |

Quand tu modifies `app_database.dart`, régénère avec :

```bash
dart run build_runner build
```

---

## Comment on définit une table

Dans `app_database.dart` :

```dart
@DataClassName('FoodRow')   // nom de la classe générée
class Foods extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get expirationDate => dateTime()();
  // ...
  @override
  Set<Column<Object>> get primaryKey => {id};
}
```

Puis :

```dart
@DriftDatabase(tables: [Foods])
class AppDatabase extends _$AppDatabase { ... }
```

`_$AppDatabase` vient du fichier généré `.g.dart`.

---

## Opérations CRUD utilisées ici

### Lire tous les aliments

```dart
final rows = await (select(foods)..orderBy([...])).get();
```

### Ajouter / mettre à jour

```dart
await into(foods).insertOnConflictUpdate(companion);
```

Si l’`id` existe déjà → update, sinon → insert.

### Supprimer

```dart
await (delete(foods)..where((t) => t.id.equals(id))).go();
```

### Companion / `Value(...)`

Pour une insertion, Drift utilise un `FoodsCompanion`.  
Les champs optionnels ou avec défaut passent dans `Value(...)` :

```dart
status: Value(food.status.name),
imageUrl: Value(food.imageUrl), // peut être null
```

---

## Migration depuis SharedPreferences

Au démarrage (`main.dart`) :

1. Ouverture de la BDD Drift
2. `migrateFromSharedPreferencesIfNeeded()`
   - Si le flag `drift_migrated_v1` n’existe pas
   - On lit l’ancien JSON `foodsList`
   - On l’insère dans SQLite
   - On pose le flag pour ne pas migrer deux fois

Les anciens SharedPreferences restent en backup, mais l’app ne s’en sert plus au quotidien.

---

## Version de schéma

```dart
@override
int get schemaVersion => 1;
```

Si tu **ajoutes une colonne** plus tard :

1. Incrémente `schemaVersion` (ex. `2`)
2. Ajoute la logique dans `MigrationStrategy.onUpgrade`
3. Relance `build_runner`

Sans ça, les utilisateurs déjà installés peuvent planter au lancement.

---

## Pourquoi Drift plutôt que SharedPreferences ?

| SharedPreferences | Drift (SQLite) |
|---|---|
| Un blob JSON | Lignes / colonnes |
| Réécrit toute la liste | Update d’une seule ligne |
| OK pour 10–50 items | Scale mieux |
| Filtres en mémoire | Possibilité de filtrer en SQL |

Aujourd’hui les filtres UI restent en mémoire dans `FoodProvider` (simple). Plus tard, on pourra les faire directement en SQL Drift si la liste grossit.

---

## Mini glossaire

- **SQLite** : moteur de BDD locale (fichier sur le device)
- **Table** : comme un tableau Excel (ici `foods`)
- **Row** : une ligne = un aliment
- **Codegen / build_runner** : génère `.g.dart` à partir de ton schéma
- **Companion** : objet d’insertion/update Drift
- **schemaVersion** : numéro de version de ta structure SQL

---

## Pour aller plus loin

Doc officielle : https://drift.simonbinder.eu/

Dans ce repo, commence toujours par lire `lib/database/app_database.dart` : c’est le seul fichier Drift que tu dois vraiment maîtriser au début.
