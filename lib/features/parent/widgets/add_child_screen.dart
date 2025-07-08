import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class AddChildScreen extends StatefulWidget {
  final Child? child; // For editing existing child
  
  const AddChildScreen({super.key, this.child});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _schoolController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _medicalNotesController = TextEditingController();
  
  String _selectedGender = 'Male';
  String _selectedBloodType = 'O+';
  bool _hasAllergies = false;
  bool _hasSpecialNeeds = false;
  String _profileImagePath = '';

  @override
  void initState() {
    super.initState();
    if (widget.child != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final child = widget.child!;
    _nameController.text = child.name;
    _gradeController.text = child.grade;
    _schoolController.text = child.school;
    _emergencyContactController.text = child.emergencyContact;
    _medicalNotesController.text = child.medicalNotes;
    _selectedGender = child.gender;
    _selectedBloodType = child.bloodType;
    _hasAllergies = child.hasAllergies;
    _hasSpecialNeeds = child.hasSpecialNeeds;
    _profileImagePath = child.profileImagePath;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.child != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Child' : 'Add Child'),
        backgroundColor: AppColors.parentColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveChild,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.parentColor.withOpacity(0.1),
                      backgroundImage: _profileImagePath.isNotEmpty 
                          ? AssetImage(_profileImagePath) 
                          : null,
                      child: _profileImagePath.isEmpty
                          ? Icon(
                              Icons.child_care,
                              size: 50,
                              color: AppColors.parentColor,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _selectProfileImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Basic Information
              Text(
                'Basic Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter child\'s name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.wc),
                      ),
                      items: ['Male', 'Female', 'Other'].map((gender) {
                        return DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: TextFormField(
                      controller: _gradeController,
                      decoration: const InputDecoration(
                        labelText: 'Grade/Class *',
                        prefixIcon: Icon(Icons.school),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter grade';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              TextFormField(
                controller: _schoolController,
                decoration: const InputDecoration(
                  labelText: 'School Name *',
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter school name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Emergency Contact
              Text(
                'Emergency Contact',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              TextFormField(
                controller: _emergencyContactController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Number *',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter emergency contact';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Medical Information
              Text(
                'Medical Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              DropdownButtonFormField<String>(
                value: _selectedBloodType,
                decoration: const InputDecoration(
                  labelText: 'Blood Type',
                  prefixIcon: Icon(Icons.bloodtype),
                ),
                items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBloodType = value!;
                  });
                },
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              SwitchListTile(
                title: const Text('Has Allergies'),
                subtitle: const Text('Check if child has any known allergies'),
                value: _hasAllergies,
                onChanged: (value) {
                  setState(() {
                    _hasAllergies = value;
                  });
                },
                activeColor: AppColors.parentColor,
              ),

              SwitchListTile(
                title: const Text('Has Special Needs'),
                subtitle: const Text('Check if child requires special assistance'),
                value: _hasSpecialNeeds,
                onChanged: (value) {
                  setState(() {
                    _hasSpecialNeeds = value;
                  });
                },
                activeColor: AppColors.parentColor,
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              TextFormField(
                controller: _medicalNotesController,
                decoration: const InputDecoration(
                  labelText: 'Medical Notes',
                  prefixIcon: Icon(Icons.medical_information),
                  hintText: 'Any medical conditions, medications, or special instructions...',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: AppConstants.paddingXLarge),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChild,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.parentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    isEditing ? 'Update Child' : 'Add Child',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectProfileImage() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Profile Picture',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  'Camera',
                  Icons.camera_alt,
                  () {
                    Navigator.pop(context);
                    _takePicture();
                  },
                ),
                _buildImageOption(
                  'Gallery',
                  Icons.photo_library,
                  () {
                    Navigator.pop(context);
                    _selectFromGallery();
                  },
                ),
                _buildImageOption(
                  'Remove',
                  Icons.delete,
                  () {
                    Navigator.pop(context);
                    setState(() {
                      _profileImagePath = '';
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.parentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.parentColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(title),
        ],
      ),
    );
  }

  void _takePicture() {
    // TODO: Implement camera functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera functionality will be implemented')),
    );
  }

  void _selectFromGallery() {
    // TODO: Implement gallery selection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gallery selection will be implemented')),
    );
  }

  void _saveChild() {
    if (_formKey.currentState!.validate()) {
      final child = Child(
        id: widget.child?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        gender: _selectedGender,
        grade: _gradeController.text,
        school: _schoolController.text,
        emergencyContact: _emergencyContactController.text,
        bloodType: _selectedBloodType,
        hasAllergies: _hasAllergies,
        hasSpecialNeeds: _hasSpecialNeeds,
        medicalNotes: _medicalNotesController.text,
        profileImagePath: _profileImagePath,
      );

      Navigator.pop(context, child);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gradeController.dispose();
    _schoolController.dispose();
    _emergencyContactController.dispose();
    _medicalNotesController.dispose();
    super.dispose();
  }
}

class Child {
  final String id;
  final String name;
  final String gender;
  final String grade;
  final String school;
  final String emergencyContact;
  final String bloodType;
  final bool hasAllergies;
  final bool hasSpecialNeeds;
  final String medicalNotes;
  final String profileImagePath;

  Child({
    required this.id,
    required this.name,
    required this.gender,
    required this.grade,
    required this.school,
    required this.emergencyContact,
    required this.bloodType,
    required this.hasAllergies,
    required this.hasSpecialNeeds,
    required this.medicalNotes,
    required this.profileImagePath,
  });
}
