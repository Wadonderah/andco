import 'package:flutter/material.dart';

enum AuthButtonType {
  primary,
  secondary,
  outlined,
  google,
  phone,
  logout,
}

enum AuthButtonSize {
  small,
  medium,
  large,
}

class ResponsiveAuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AuthButtonType type;
  final AuthButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final Color? customColor;
  final double? width;
  final bool isFullWidth;

  const ResponsiveAuthButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AuthButtonType.primary,
    this.size = AuthButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.customColor,
    this.width,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: _getButtonHeight(isSmallScreen),
      child: _buildButton(context, isSmallScreen),
    );
  }

  double _getButtonHeight(bool isSmallScreen) {
    switch (size) {
      case AuthButtonSize.small:
        return isSmallScreen ? 40 : 44;
      case AuthButtonSize.medium:
        return isSmallScreen ? 48 : 52;
      case AuthButtonSize.large:
        return isSmallScreen ? 56 : 60;
    }
  }

  double _getFontSize(bool isSmallScreen) {
    switch (size) {
      case AuthButtonSize.small:
        return isSmallScreen ? 14 : 15;
      case AuthButtonSize.medium:
        return isSmallScreen ? 16 : 17;
      case AuthButtonSize.large:
        return isSmallScreen ? 18 : 19;
    }
  }

  double _getIconSize(bool isSmallScreen) {
    switch (size) {
      case AuthButtonSize.small:
        return isSmallScreen ? 18 : 20;
      case AuthButtonSize.medium:
        return isSmallScreen ? 20 : 22;
      case AuthButtonSize.large:
        return isSmallScreen ? 22 : 24;
    }
  }

  Widget _buildButton(BuildContext context, bool isSmallScreen) {
    switch (type) {
      case AuthButtonType.primary:
        return _buildPrimaryButton(context, isSmallScreen);
      case AuthButtonType.secondary:
        return _buildSecondaryButton(context, isSmallScreen);
      case AuthButtonType.outlined:
        return _buildOutlinedButton(context, isSmallScreen);
      case AuthButtonType.google:
        return _buildGoogleButton(context, isSmallScreen);
      case AuthButtonType.phone:
        return _buildPhoneButton(context, isSmallScreen);
      case AuthButtonType.logout:
        return _buildLogoutButton(context, isSmallScreen);
    }
  }

  Widget _buildPrimaryButton(BuildContext context, bool isSmallScreen) {
    final color = customColor ?? Theme.of(context).primaryColor;
    
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
        ),
        elevation: 0,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 24,
          vertical: isSmallScreen ? 8 : 12,
        ),
      ),
      child: _buildButtonContent(context, isSmallScreen, Colors.white),
    );
  }

  Widget _buildSecondaryButton(BuildContext context, bool isSmallScreen) {
    final color = customColor ?? Theme.of(context).primaryColor;
    
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
        ),
        elevation: 0,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 24,
          vertical: isSmallScreen ? 8 : 12,
        ),
      ),
      child: _buildButtonContent(context, isSmallScreen, color),
    );
  }

  Widget _buildOutlinedButton(BuildContext context, bool isSmallScreen) {
    final color = customColor ?? Colors.grey[600]!;
    
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 24,
          vertical: isSmallScreen ? 8 : 12,
        ),
      ),
      child: _buildButtonContent(context, isSmallScreen, Colors.white),
    );
  }

  Widget _buildGoogleButton(BuildContext context, bool isSmallScreen) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        side: const BorderSide(color: Colors.transparent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 24,
          vertical: isSmallScreen ? 8 : 12,
        ),
      ),
      child: _buildGoogleButtonContent(context, isSmallScreen),
    );
  }

  Widget _buildPhoneButton(BuildContext context, bool isSmallScreen) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.grey[600]!),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 24,
          vertical: isSmallScreen ? 8 : 12,
        ),
      ),
      child: _buildButtonContent(context, isSmallScreen, Colors.white),
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool isSmallScreen) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
        ),
        elevation: 0,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 24,
          vertical: isSmallScreen ? 8 : 12,
        ),
      ),
      child: _buildButtonContent(context, isSmallScreen, Colors.white),
    );
  }

  Widget _buildButtonContent(BuildContext context, bool isSmallScreen, Color textColor) {
    if (isLoading) {
      return SizedBox(
        width: _getIconSize(isSmallScreen),
        height: _getIconSize(isSmallScreen),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: _getIconSize(isSmallScreen),
            color: textColor,
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: _getFontSize(isSmallScreen),
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: _getFontSize(isSmallScreen),
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildGoogleButtonContent(BuildContext context, bool isSmallScreen) {
    if (isLoading) {
      return SizedBox(
        width: _getIconSize(isSmallScreen),
        height: _getIconSize(isSmallScreen),
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _getIconSize(isSmallScreen),
          height: _getIconSize(isSmallScreen),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Center(
            child: Text(
              'G',
              style: TextStyle(
                fontSize: _getFontSize(isSmallScreen) - 2,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: _getFontSize(isSmallScreen),
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
