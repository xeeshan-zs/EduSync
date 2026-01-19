import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class IconUtils {
  static const Map<String, IconData> iconMap = {
    // Socials
    'web': Icons.language,
    'email': Icons.email,
    'linkedin': FontAwesomeIcons.linkedin,
    'github': FontAwesomeIcons.github,
    'twitter': FontAwesomeIcons.twitter,
    'instagram': FontAwesomeIcons.instagram,
    'facebook': FontAwesomeIcons.facebook,
    'youtube': FontAwesomeIcons.youtube,
    'tiktok': FontAwesomeIcons.tiktok,
    'discord': FontAwesomeIcons.discord,
    'medium': FontAwesomeIcons.medium,
    'stack-overflow': FontAwesomeIcons.stackOverflow,
    'whatsapp': FontAwesomeIcons.whatsapp,
    'upwork': FontAwesomeIcons.upwork,
    'fiverr': FontAwesomeIcons.briefcase, // Fallback as actual icon is missing in this version

    // Generic / Tech / Role Icons
    'code': FontAwesomeIcons.code,
    'laptop': FontAwesomeIcons.laptop,
    'laptop-code': FontAwesomeIcons.laptopCode,
    'server': FontAwesomeIcons.server,
    'database': FontAwesomeIcons.database,
    'cloud': FontAwesomeIcons.cloud,
    'bug': FontAwesomeIcons.bug,
    'terminal': FontAwesomeIcons.terminal,
    'mobile': FontAwesomeIcons.mobile,
    'rocket': FontAwesomeIcons.rocket,
    'gamepad': FontAwesomeIcons.gamepad,
    'palette': FontAwesomeIcons.palette,
    'pen-nib': FontAwesomeIcons.penNib,
    'briefcase': FontAwesomeIcons.briefcase,
    'user-tie': FontAwesomeIcons.userTie,
    'graduation-cap': FontAwesomeIcons.graduationCap,
    'school': FontAwesomeIcons.school,
    'book': FontAwesomeIcons.book,
    'brain': FontAwesomeIcons.brain,
    'lightbulb': FontAwesomeIcons.lightbulb,
    'chart-line': FontAwesomeIcons.chartLine,
    'globe': FontAwesomeIcons.globe,
    'link': FontAwesomeIcons.link,
  };

  static IconData getIcon(String key) {
    return iconMap[key] ?? Icons.public; // Default to globe if not found
  }
}
