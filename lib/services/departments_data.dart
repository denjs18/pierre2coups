import '../models/department.dart';

class DepartmentsData {
  // Liste complète des 101 départements français
  static const List<Department> departments = [
    // Auvergne-Rhône-Alpes
    Department(code: '01', name: 'Ain', region: 'Auvergne-Rhône-Alpes'),
    Department(code: '03', name: 'Allier', region: 'Auvergne-Rhône-Alpes'),
    Department(code: '07', name: 'Ardèche', region: 'Auvergne-Rhône-Alpes'),
    Department(code: '15', name: 'Cantal', region: 'Auvergne-Rhône-Alpes'),
    Department(code: '26', name: 'Drôme', region: 'Auvergne-Rhône-Alpes'),
    Department(code: '38', name: 'Isère', region: 'Auvergne-Rhône-Alpes'),
    Department(code: '42', name: 'Loire', region: 'Auvergne-Rhône-Alpes'),
    Department(code: '43', name: 'Haute-Loire', region: 'Auvergne-Rhône-Alpes'),
    Department(code: '63', name: 'Puy-de-Dôme', region: 'Auvergne-Rhône-Alpes'),
    Department(code: '69', name: 'Rhône', region: 'Auvergne-Rhône-Alpes'),
    Department(code: '73', name: 'Savoie', region: 'Auvergne-Rhône-Alpes'),
    Department(code: '74', name: 'Haute-Savoie', region: 'Auvergne-Rhône-Alpes'),

    // Bourgogne-Franche-Comté
    Department(code: '21', name: 'Côte-d\'Or', region: 'Bourgogne-Franche-Comté'),
    Department(code: '25', name: 'Doubs', region: 'Bourgogne-Franche-Comté'),
    Department(code: '39', name: 'Jura', region: 'Bourgogne-Franche-Comté'),
    Department(code: '58', name: 'Nièvre', region: 'Bourgogne-Franche-Comté'),
    Department(code: '70', name: 'Haute-Saône', region: 'Bourgogne-Franche-Comté'),
    Department(code: '71', name: 'Saône-et-Loire', region: 'Bourgogne-Franche-Comté'),
    Department(code: '89', name: 'Yonne', region: 'Bourgogne-Franche-Comté'),
    Department(code: '90', name: 'Territoire de Belfort', region: 'Bourgogne-Franche-Comté'),

    // Bretagne
    Department(code: '22', name: 'Côtes-d\'Armor', region: 'Bretagne'),
    Department(code: '29', name: 'Finistère', region: 'Bretagne'),
    Department(code: '35', name: 'Ille-et-Vilaine', region: 'Bretagne'),
    Department(code: '56', name: 'Morbihan', region: 'Bretagne'),

    // Centre-Val de Loire
    Department(code: '18', name: 'Cher', region: 'Centre-Val de Loire'),
    Department(code: '28', name: 'Eure-et-Loir', region: 'Centre-Val de Loire'),
    Department(code: '36', name: 'Indre', region: 'Centre-Val de Loire'),
    Department(code: '37', name: 'Indre-et-Loire', region: 'Centre-Val de Loire'),
    Department(code: '41', name: 'Loir-et-Cher', region: 'Centre-Val de Loire'),
    Department(code: '45', name: 'Loiret', region: 'Centre-Val de Loire'),

    // Corse
    Department(code: '2A', name: 'Corse-du-Sud', region: 'Corse'),
    Department(code: '2B', name: 'Haute-Corse', region: 'Corse'),

    // Grand Est
    Department(code: '08', name: 'Ardennes', region: 'Grand Est'),
    Department(code: '10', name: 'Aube', region: 'Grand Est'),
    Department(code: '51', name: 'Marne', region: 'Grand Est'),
    Department(code: '52', name: 'Haute-Marne', region: 'Grand Est'),
    Department(code: '54', name: 'Meurthe-et-Moselle', region: 'Grand Est'),
    Department(code: '55', name: 'Meuse', region: 'Grand Est'),
    Department(code: '57', name: 'Moselle', region: 'Grand Est'),
    Department(code: '67', name: 'Bas-Rhin', region: 'Grand Est'),
    Department(code: '68', name: 'Haut-Rhin', region: 'Grand Est'),
    Department(code: '88', name: 'Vosges', region: 'Grand Est'),

    // Hauts-de-France
    Department(code: '02', name: 'Aisne', region: 'Hauts-de-France'),
    Department(code: '59', name: 'Nord', region: 'Hauts-de-France'),
    Department(code: '60', name: 'Oise', region: 'Hauts-de-France'),
    Department(code: '62', name: 'Pas-de-Calais', region: 'Hauts-de-France'),
    Department(code: '80', name: 'Somme', region: 'Hauts-de-France'),

    // Île-de-France
    Department(code: '75', name: 'Paris', region: 'Île-de-France'),
    Department(code: '77', name: 'Seine-et-Marne', region: 'Île-de-France'),
    Department(code: '78', name: 'Yvelines', region: 'Île-de-France'),
    Department(code: '91', name: 'Essonne', region: 'Île-de-France'),
    Department(code: '92', name: 'Hauts-de-Seine', region: 'Île-de-France'),
    Department(code: '93', name: 'Seine-Saint-Denis', region: 'Île-de-France'),
    Department(code: '94', name: 'Val-de-Marne', region: 'Île-de-France'),
    Department(code: '95', name: 'Val-d\'Oise', region: 'Île-de-France'),

    // Normandie
    Department(code: '14', name: 'Calvados', region: 'Normandie'),
    Department(code: '27', name: 'Eure', region: 'Normandie'),
    Department(code: '50', name: 'Manche', region: 'Normandie'),
    Department(code: '61', name: 'Orne', region: 'Normandie'),
    Department(code: '76', name: 'Seine-Maritime', region: 'Normandie'),

    // Nouvelle-Aquitaine
    Department(code: '16', name: 'Charente', region: 'Nouvelle-Aquitaine'),
    Department(code: '17', name: 'Charente-Maritime', region: 'Nouvelle-Aquitaine'),
    Department(code: '19', name: 'Corrèze', region: 'Nouvelle-Aquitaine'),
    Department(code: '23', name: 'Creuse', region: 'Nouvelle-Aquitaine'),
    Department(code: '24', name: 'Dordogne', region: 'Nouvelle-Aquitaine'),
    Department(code: '33', name: 'Gironde', region: 'Nouvelle-Aquitaine'),
    Department(code: '40', name: 'Landes', region: 'Nouvelle-Aquitaine'),
    Department(code: '47', name: 'Lot-et-Garonne', region: 'Nouvelle-Aquitaine'),
    Department(code: '64', name: 'Pyrénées-Atlantiques', region: 'Nouvelle-Aquitaine'),
    Department(code: '79', name: 'Deux-Sèvres', region: 'Nouvelle-Aquitaine'),
    Department(code: '86', name: 'Vienne', region: 'Nouvelle-Aquitaine'),
    Department(code: '87', name: 'Haute-Vienne', region: 'Nouvelle-Aquitaine'),

    // Occitanie
    Department(code: '09', name: 'Ariège', region: 'Occitanie'),
    Department(code: '11', name: 'Aude', region: 'Occitanie'),
    Department(code: '12', name: 'Aveyron', region: 'Occitanie'),
    Department(code: '30', name: 'Gard', region: 'Occitanie'),
    Department(code: '31', name: 'Haute-Garonne', region: 'Occitanie'),
    Department(code: '32', name: 'Gers', region: 'Occitanie'),
    Department(code: '34', name: 'Hérault', region: 'Occitanie'),
    Department(code: '46', name: 'Lot', region: 'Occitanie'),
    Department(code: '48', name: 'Lozère', region: 'Occitanie'),
    Department(code: '65', name: 'Hautes-Pyrénées', region: 'Occitanie'),
    Department(code: '66', name: 'Pyrénées-Orientales', region: 'Occitanie'),
    Department(code: '81', name: 'Tarn', region: 'Occitanie'),
    Department(code: '82', name: 'Tarn-et-Garonne', region: 'Occitanie'),

    // Pays de la Loire
    Department(code: '44', name: 'Loire-Atlantique', region: 'Pays de la Loire'),
    Department(code: '49', name: 'Maine-et-Loire', region: 'Pays de la Loire'),
    Department(code: '53', name: 'Mayenne', region: 'Pays de la Loire'),
    Department(code: '72', name: 'Sarthe', region: 'Pays de la Loire'),
    Department(code: '85', name: 'Vendée', region: 'Pays de la Loire'),

    // Provence-Alpes-Côte d'Azur
    Department(code: '04', name: 'Alpes-de-Haute-Provence', region: 'Provence-Alpes-Côte d\'Azur'),
    Department(code: '05', name: 'Hautes-Alpes', region: 'Provence-Alpes-Côte d\'Azur'),
    Department(code: '06', name: 'Alpes-Maritimes', region: 'Provence-Alpes-Côte d\'Azur'),
    Department(code: '13', name: 'Bouches-du-Rhône', region: 'Provence-Alpes-Côte d\'Azur'),
    Department(code: '83', name: 'Var', region: 'Provence-Alpes-Côte d\'Azur'),
    Department(code: '84', name: 'Vaucluse', region: 'Provence-Alpes-Côte d\'Azur'),

    // DROM (Départements et Régions d'Outre-Mer)
    Department(code: '971', name: 'Guadeloupe', region: 'Guadeloupe'),
    Department(code: '972', name: 'Martinique', region: 'Martinique'),
    Department(code: '973', name: 'Guyane', region: 'Guyane'),
    Department(code: '974', name: 'La Réunion', region: 'La Réunion'),
    Department(code: '976', name: 'Mayotte', region: 'Mayotte'),
  ];

  /// Récupérer un département par son code
  static Department? getDepartment(String code) {
    try {
      return departments.firstWhere(
        (dept) => dept.code.toLowerCase() == code.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Récupérer tous les départements d'une région
  static List<Department> getDepartmentsByRegion(String region) {
    return departments
        .where((dept) => dept.region == region)
        .toList();
  }

  /// Récupérer la liste de toutes les régions (sans doublons)
  static List<String> getAllRegions() {
    final regions = departments.map((dept) => dept.region).toSet().toList();
    regions.sort();
    return regions;
  }

  /// Rechercher des départements par nom ou code
  static List<Department> search(String query) {
    final lowerQuery = query.toLowerCase();
    return departments
        .where((dept) =>
            dept.name.toLowerCase().contains(lowerQuery) ||
            dept.code.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Vérifier si un code de département est valide
  static bool isValidCode(String code) {
    return getDepartment(code) != null;
  }
}
