import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/child_model.dart';
import '../../../shared/widgets/loading_overlay.dart';

class EnhancedAddChildScreen extends ConsumerStatefulWidget {
  final ChildModel? child;

  const EnhancedAddChildScreen({super.key, this.child});

  @override
  ConsumerState<EnhancedAddChildScreen> createState() => _EnhancedAddChildScreenState();
}

class _EnhancedAddChildScreenState extends ConsumerState<EnhancedAddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _classController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _medicalInfoController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  
  bool _isLoading = false;
  String? _profileImagePath;
  DateTime? _selectedDateOfBirth;
  String _selectedGender = 'Male';
  
  final List<String> _genders = ['Male', 'Female'];
  final List<String> _grades = [
    'Pre-K', 'Kindergarten', '1st Grade', '2nd Grade', '3rd Grade', 
    '4th Grade', '5th Grade', '6th Grade', '7th Grade', '8th Grade',
    '9th Grade', '10th Grade', '11th Grade', '12th Grade'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.child != null) {
      _loadChildData();
    }
  }

  void _loadChildData() {
    final child = widget.child!;
    _nameController.text = child.name;
    _gradeController.text = child.grade;
    _classController.text = child.className;
    _studentIdController.text = child.studentId ?? '';
    _medicalInfoController.text = child.medicalInfo ?? '';
    _emergencyContactController.text = child.emergencyContact ?? '';
    _emergencyPhoneController.text = child.emergencyContactPhone ?? '';
    _profileImagePath = child.photoUrl;
    _selectedDateOfBirth = child.dateOfBirth;
    _selectedGender = child.gender ?? 'Male';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gradeController.dispose();
    _classController.dispose();
    _studentIdController.dispose();
    _medicalInfoController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.child == null ? 'Add Child' : 'Edit Child'),
        backgroundColor: AppColors.parentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChild,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture Section
                _buildProfilePictureSection(),
                
                const SizedBox(height: AppConstants.paddingLarge),
                
                // Basic Information
                _buildBasicInformationSection(),
                
                const SizedBox(height: AppConstants.paddingLarge),
                
                // School Information
                _buildSchoolInformationSection(),
                
                const SizedBox(height: AppConstants.paddingLarge),
                
                // Medical Information
                _buildMedicalInformationSection(),
                
                const SizedBox(height: AppConstants.paddingLarge),
                
                // Emergency Contact
                _buildEmergencyContactSection(),
                
                const SizedBox(height: AppConstants.paddingLarge * 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.parentColor.withOpacity(0.1),
                backgroundImage: _profileImagePath != null 
                  ? NetworkImage(_profileImagePath!) 
                  : null,
                child: _profileImagePath == null 
                  ? Icon(
                      _selectedGender == 'Male' ? Icons.boy : Icons.girl,
                      size: 60, 
                      color: AppColors.parentColor,
                    )
                  : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.parentColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: IconButton(
                    onPressed: _changeProfilePicture,
                    icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Tap to add/change photo',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInformationSection() {
    return _buildSection(
      'Basic Information',
      Icons.person,
      [
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              borderSide: const BorderSide(color: AppColors.parentColor),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter child\'s full name';
            }
            return null;
          },
        ),
        
        const SizedBox(height: AppConstants.paddingMedium),
        
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: InputDecoration(
            labelText: 'Gender',
            prefixIcon: const Icon(Icons.wc),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              borderSide: const BorderSide(color: AppColors.parentColor),
            ),
          ),
          items: _genders.map((gender) {
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
        
        const SizedBox(height: AppConstants.paddingMedium),
        
        InkWell(
          onTap: _selectDateOfBirth,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Date of Birth',
              prefixIcon: const Icon(Icons.calendar_today),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                borderSide: const BorderSide(color: AppColors.parentColor),
              ),
            ),
            child: Text(
              _selectedDateOfBirth != null
                  ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                  : 'Select date of birth',
              style: TextStyle(
                color: _selectedDateOfBirth != null 
                  ? AppColors.textPrimary 
                  : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSchoolInformationSection() {
    return _buildSection(
      'School Information',
      Icons.school,
      [
        DropdownButtonFormField<String>(
          value: _grades.contains(_gradeController.text) ? _gradeController.text : null,
          decoration: InputDecoration(
            labelText: 'Grade',
            prefixIcon: const Icon(Icons.grade),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              borderSide: const BorderSide(color: AppColors.parentColor),
            ),
          ),
          items: _grades.map((grade) {
            return DropdownMenuItem(
              value: grade,
              child: Text(grade),
            );
          }).toList(),
          onChanged: (value) {
            _gradeController.text = value!;
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a grade';
            }
            return null;
          },
        ),
        
        const SizedBox(height: AppConstants.paddingMedium),
        
        TextFormField(
          controller: _classController,
          decoration: InputDecoration(
            labelText: 'Class/Section',
            prefixIcon: const Icon(Icons.class_),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              borderSide: const BorderSide(color: AppColors.parentColor),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter class/section';
            }
            return null;
          },
        ),
        
        const SizedBox(height: AppConstants.paddingMedium),
        
        TextFormField(
          controller: _studentIdController,
          decoration: InputDecoration(
            labelText: 'Student ID (Optional)',
            prefixIcon: const Icon(Icons.badge),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              borderSide: const BorderSide(color: AppColors.parentColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalInformationSection() {
    return _buildSection(
      'Medical Information',
      Icons.medical_services,
      [
        TextFormField(
          controller: _medicalInfoController,
          decoration: InputDecoration(
            labelText: 'Medical Information (Optional)',
            prefixIcon: const Icon(Icons.medical_information),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              borderSide: const BorderSide(color: AppColors.parentColor),
            ),
            helperText: 'Include allergies, medications, special needs, etc.',
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildEmergencyContactSection() {
    return _buildSection(
      'Emergency Contact',
      Icons.emergency,
      [
        TextFormField(
          controller: _emergencyContactController,
          decoration: InputDecoration(
            labelText: 'Emergency Contact Name',
            prefixIcon: const Icon(Icons.contact_emergency),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              borderSide: const BorderSide(color: AppColors.parentColor),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter emergency contact name';
            }
            return null;
          },
        ),
        
        const SizedBox(height: AppConstants.paddingMedium),
        
        TextFormField(
          controller: _emergencyPhoneController,
          decoration: InputDecoration(
            labelText: 'Emergency Contact Phone',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              borderSide: const BorderSide(color: AppColors.parentColor),
            ),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter emergency contact phone';
            }
            if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(value)) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.parentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          ...children,
        ],
      ),
    );
  }

  // Action methods
  void _changeProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      try {
        final XFile? image = await picker.pickImage(source: source);
        if (image != null) {
          setState(() {
            _profileImagePath = image.path;
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }

  void _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 5)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  void _saveChild() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date of birth')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authControllerProvider);
      final user = authState.value;
      
      if (user == null) {
        throw Exception('User not found');
      }

      final childRepo = ref.read(childRepositoryProvider);
      final now = DateTime.now();
      
      final child = ChildModel(
        id: widget.child?.id ?? '',
        name: _nameController.text.trim(),
        parentId: user.uid,
        schoolId: user.schoolId ?? '',
        grade: _gradeController.text.trim(),
        className: _classController.text.trim(),
        photoUrl: _profileImagePath,
        dateOfBirth: _selectedDateOfBirth!,
        medicalInfo: _medicalInfoController.text.trim().isNotEmpty 
          ? _medicalInfoController.text.trim() 
          : null,
        emergencyContact: _emergencyContactController.text.trim().isNotEmpty 
          ? _emergencyContactController.text.trim() 
          : null,
        emergencyContactPhone: _emergencyPhoneController.text.trim().isNotEmpty 
          ? _emergencyPhoneController.text.trim() 
          : null,
        studentId: _studentIdController.text.trim().isNotEmpty 
          ? _studentIdController.text.trim() 
          : null,
        gender: _selectedGender,
        isActive: true,
        createdAt: widget.child?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.child == null) {
        // Create new child
        await childRepo.create(child);
      } else {
        // Update existing child
        await childRepo.update(widget.child!.id, child.toMap());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${child.name} ${widget.child == null ? 'added' : 'updated'} successfully'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, child);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving child: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
