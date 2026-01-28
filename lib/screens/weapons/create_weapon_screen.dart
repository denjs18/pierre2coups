import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/weapon.dart';
import '../../theme/app_theme.dart';

class CreateWeaponScreen extends StatefulWidget {
  final String? initialSearchQuery;

  const CreateWeaponScreen({
    Key? key,
    this.initialSearchQuery,
  }) : super(key: key);

  @override
  State<CreateWeaponScreen> createState() => _CreateWeaponScreenState();
}

class _CreateWeaponScreenState extends State<CreateWeaponScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();
  final _caliberController = TextEditingController();

  String _selectedCategory = 'Pistolet';
  bool _isLoading = false;

  final List<String> _categories = [
    'Pistolet',
    'Revolver',
    'Carabine',
    'Fusil',
    'Arme de poing',
    'Arme longue',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null) {
      _nameController.text = widget.initialSearchQuery!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _caliberController.dispose();
    super.dispose();
  }

  Future<void> _saveWeapon() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final weapon = Weapon(
        id: '', // Will be generated
        name: _nameController.text.trim(),
        manufacturer: _manufacturerController.text.trim(),
        model: _modelController.text.trim(),
        caliber: _caliberController.text.trim(),
        category: _selectedCategory,
        usageCount: 0,
        createdAt: DateTime.now(),
      );

      // Sauvegarder en local
      await DatabaseHelper.instance.saveWeapon(weapon.toMap());

      if (mounted) {
        Navigator.pop(context, weapon);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('NOUVELLE ARME'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentPrimary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.accentPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cette arme sera disponible pour tous vos futurs tirs et pourra être partagée avec d\'autres utilisateurs.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nom (obligatoire)
            Text(
              'NOM DE L\'ARME *',
              style: AppTheme.labelStyle.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Ex: Glock 17',
                prefixIcon: Icon(Icons.gps_fixed, size: 20),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est obligatoire';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),

            // Fabricant (optionnel)
            Text(
              'FABRICANT',
              style: AppTheme.labelStyle.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _manufacturerController,
              decoration: const InputDecoration(
                hintText: 'Ex: Glock',
                prefixIcon: Icon(Icons.business, size: 20),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),

            // Modèle (optionnel)
            Text(
              'MODÈLE',
              style: AppTheme.labelStyle.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _modelController,
              decoration: const InputDecoration(
                hintText: 'Ex: Gen 5',
                prefixIcon: Icon(Icons.category, size: 20),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),

            // Calibre (optionnel)
            Text(
              'CALIBRE',
              style: AppTheme.labelStyle.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _caliberController,
              decoration: const InputDecoration(
                hintText: 'Ex: 9mm, .45 ACP, 5.56mm',
                prefixIcon: Icon(Icons.straighten, size: 20),
              ),
            ),
            const SizedBox(height: 20),

            // Catégorie (obligatoire)
            Text(
              'CATÉGORIE *',
              style: AppTheme.labelStyle.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: AppTheme.accentPrimary,
                  ),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                  ),
                  dropdownColor: AppTheme.surfaceColor,
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(category),
                            size: 18,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Text(category),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Bouton de sauvegarde
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveWeapon,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(
                _isLoading ? 'CRÉATION EN COURS...' : 'CRÉER L\'ARME',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Pistolet':
      case 'Arme de poing':
        return Icons.gps_fixed;
      case 'Revolver':
        return Icons.album;
      case 'Carabine':
      case 'Fusil':
      case 'Arme longue':
        return Icons.architecture;
      default:
        return Icons.category;
    }
  }
}
