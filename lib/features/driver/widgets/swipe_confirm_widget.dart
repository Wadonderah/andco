import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class SwipeConfirmWidget extends StatefulWidget {
  final String studentName;
  final String action; // 'pickup' or 'dropoff'
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final Color? backgroundColor;
  final Color? confirmColor;

  const SwipeConfirmWidget({
    super.key,
    required this.studentName,
    required this.action,
    required this.onConfirm,
    this.onCancel,
    this.backgroundColor,
    this.confirmColor,
  });

  @override
  State<SwipeConfirmWidget> createState() => _SwipeConfirmWidgetState();
}

class _SwipeConfirmWidgetState extends State<SwipeConfirmWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  double _dragPosition = 0.0;
  bool _isConfirmed = false;
  bool _isDragging = false;
  
  static const double _threshold = 0.8; // 80% swipe to confirm
  static const double _buttonSize = 60.0;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width - (AppConstants.paddingMedium * 2);
    final maxDragDistance = screenWidth - _buttonSize - 20; // 20 for padding
    
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background gradient
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: [0.0, _dragPosition / maxDragDistance, 1.0],
                    colors: [
                      (widget.confirmColor ?? AppColors.success).withOpacity(0.3),
                      (widget.confirmColor ?? AppColors.success).withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Text content
          Center(
            child: AnimatedOpacity(
              opacity: _isConfirmed ? 0.0 : (1.0 - (_dragPosition / maxDragDistance) * 0.7),
              duration: const Duration(milliseconds: 200),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Swipe to confirm ${widget.action}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    widget.studentName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Swipe button
          AnimatedPositioned(
            duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            left: 10 + _dragPosition,
            top: 10,
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isDragging ? 1.1 : _pulseAnimation.value,
                    child: Container(
                      width: _buttonSize,
                      height: _buttonSize,
                      decoration: BoxDecoration(
                        color: _isConfirmed 
                            ? AppColors.success 
                            : (widget.confirmColor ?? AppColors.driverColor),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isConfirmed 
                            ? Icons.check 
                            : (widget.action == 'pickup' ? Icons.person_add : Icons.person_remove),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Success overlay
          if (_isConfirmed)
            Container(
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.9),
                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.action.toUpperCase()} CONFIRMED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      widget.studentName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    if (_isConfirmed) return;
    
    setState(() {
      _isDragging = true;
    });
    
    _pulseController.stop();
    HapticFeedback.lightImpact();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isConfirmed) return;
    
    final screenWidth = MediaQuery.of(context).size.width - (AppConstants.paddingMedium * 2);
    final maxDragDistance = screenWidth - _buttonSize - 20;
    
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDragDistance);
    });
    
    // Provide haptic feedback at certain thresholds
    final progress = _dragPosition / maxDragDistance;
    if (progress > 0.5 && progress < 0.6) {
      HapticFeedback.selectionClick();
    } else if (progress > _threshold && progress < _threshold + 0.1) {
      HapticFeedback.mediumImpact();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isConfirmed) return;
    
    final screenWidth = MediaQuery.of(context).size.width - (AppConstants.paddingMedium * 2);
    final maxDragDistance = screenWidth - _buttonSize - 20;
    final progress = _dragPosition / maxDragDistance;
    
    setState(() {
      _isDragging = false;
    });
    
    if (progress >= _threshold) {
      // Confirm action
      _confirmAction();
    } else {
      // Reset position
      _resetPosition();
    }
  }

  void _confirmAction() {
    setState(() {
      _isConfirmed = true;
    });
    
    HapticFeedback.heavyImpact();
    
    // Animate to final position
    _slideController.forward();
    
    // Call the confirmation callback after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      widget.onConfirm();
    });
  }

  void _resetPosition() {
    setState(() {
      _dragPosition = 0.0;
    });
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}

// Enhanced swipe confirmation screen for active route management
class SwipeConfirmScreen extends StatefulWidget {
  final List<Student> students;
  final String routeType; // 'pickup' or 'dropoff'

  const SwipeConfirmScreen({
    super.key,
    required this.students,
    required this.routeType,
  });

  @override
  State<SwipeConfirmScreen> createState() => _SwipeConfirmScreenState();
}

class _SwipeConfirmScreenState extends State<SwipeConfirmScreen> {
  late List<Student> _students;
  int _currentStudentIndex = 0;

  @override
  void initState() {
    super.initState();
    _students = List.from(widget.students);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStudentIndex >= _students.length) {
      return _buildCompletionScreen();
    }

    final currentStudent = _students[_currentStudentIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.routeType.toUpperCase()} Route'),
        backgroundColor: AppColors.driverColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showStudentList,
            icon: const Icon(Icons.list),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: AppColors.surfaceVariant,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Student ${_currentStudentIndex + 1} of ${_students.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${((_currentStudentIndex / _students.length) * 100).round()}% Complete',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                LinearProgressIndicator(
                  value: _currentStudentIndex / _students.length,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.driverColor),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                children: [
                  // Current student card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingLarge),
                      child: Column(
                        children: [
                          // Student info
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: AppColors.driverColor.withOpacity(0.1),
                                child: Text(
                                  currentStudent.name[0],
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.driverColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppConstants.paddingMedium),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentStudent.name,
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${currentStudent.grade} • Seat ${currentStudent.seatNumber}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    if (currentStudent.specialNeeds.isNotEmpty)
                                      Text(
                                        'Special needs: ${currentStudent.specialNeeds.join(', ')}',
                                        style: const TextStyle(
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppConstants.paddingLarge),

                          // Location info
                          Container(
                            padding: const EdgeInsets.all(AppConstants.paddingMedium),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      widget.routeType == 'pickup' ? Icons.home : Icons.school,
                                      color: AppColors.info,
                                    ),
                                    const SizedBox(width: AppConstants.paddingSmall),
                                    Expanded(
                                      child: Text(
                                        widget.routeType == 'pickup' 
                                            ? currentStudent.pickupLocation 
                                            : currentStudent.dropoffLocation,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppConstants.paddingSmall),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      color: AppColors.textSecondary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: AppConstants.paddingSmall),
                                    Text(
                                      'Scheduled: ${widget.routeType == 'pickup' ? currentStudent.pickupTime : currentStudent.dropoffTime}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppConstants.paddingLarge),

                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _markAsAbsent,
                                  icon: const Icon(Icons.person_off),
                                  label: const Text('Mark Absent'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(color: AppColors.error),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppConstants.paddingMedium),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _callParent,
                                  icon: const Icon(Icons.phone),
                                  label: const Text('Call Parent'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.info,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingLarge),

                  // Swipe to confirm widget
                  SwipeConfirmWidget(
                    studentName: currentStudent.name,
                    action: widget.routeType,
                    onConfirm: _confirmStudent,
                    confirmColor: AppColors.driverColor,
                  ),

                  const SizedBox(height: AppConstants.paddingLarge),

                  // Next students preview
                  if (_currentStudentIndex < _students.length - 1) ...[
                    Text(
                      'Next Students:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    
                    ...(_students.skip(_currentStudentIndex + 1).take(3).map((student) => 
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.driverColor.withOpacity(0.1),
                            child: Text(
                              student.name[0],
                              style: const TextStyle(
                                color: AppColors.driverColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(student.name),
                          subtitle: Text(
                            widget.routeType == 'pickup' 
                                ? student.pickupLocation 
                                : student.dropoffLocation,
                          ),
                          trailing: Text(
                            widget.routeType == 'pickup' 
                                ? student.pickupTime 
                                : student.dropoffTime,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ).toList()),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.routeType.toUpperCase()} Complete'),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 100,
              color: AppColors.success,
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              'Route Complete!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              'All students have been processed for ${widget.routeType}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingLarge * 2),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.home),
              label: const Text('Return to Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.driverColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmStudent() {
    setState(() {
      _currentStudentIndex++;
    });
    
    HapticFeedback.heavyImpact();
  }

  void _markAsAbsent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Absent'),
        content: Text('Mark ${_students[_currentStudentIndex].name} as absent for ${widget.routeType}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentStudentIndex++;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_students[_currentStudentIndex - 1].name} marked as absent'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Mark Absent'),
          ),
        ],
      ),
    );
  }

  void _callParent() {
    final student = _students[_currentStudentIndex];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling ${student.parentName}...')),
    );
  }

  void _showStudentList() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Student list will be implemented')),
    );
  }
}

// Student class (if not already defined)
class Student {
  final String id;
  final String name;
  final String grade;
  final String pickupLocation;
  final String dropoffLocation;
  final String pickupTime;
  final String dropoffTime;
  final String parentName;
  final String parentPhone;
  final String seatNumber;
  final List<String> specialNeeds;

  Student({
    required this.id,
    required this.name,
    required this.grade,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupTime,
    required this.dropoffTime,
    required this.parentName,
    required this.parentPhone,
    required this.seatNumber,
    required this.specialNeeds,
  });
}
