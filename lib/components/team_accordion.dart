import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Team member data model
class TeamMember {
  final String name;
  final String imagePath;
  final String role;
  final List<SocialLink> socials;

  const TeamMember({
    required this.name,
    required this.imagePath,
    required this.role,
    required this.socials,
  });
}

/// Social media link model - using FaIconData for FontAwesome compatibility
class SocialLink {
  final FaIconData icon;
  final String url;

  const SocialLink({required this.icon, required this.url});
}

/// Registry of team members
final List<TeamMember> teamMembers = [
  const TeamMember(
    name: 'Umang Gupta',
    imagePath: 'assets/UmangGupta.png',
    role: 'CORE DEVELOPER',
    socials: [
      SocialLink(icon: FontAwesomeIcons.x, url: 'https://x.com/ug_5711'),
      SocialLink(icon: FontAwesomeIcons.linkedinIn, url: 'https://www.linkedin.com/in/ug5711'),
      SocialLink(icon: FontAwesomeIcons.instagram, url: 'https://www.instagram.com/ug_5711'),
      SocialLink(icon: FontAwesomeIcons.github, url: 'https://github.com/mini-page/'),
      SocialLink(icon: FontAwesomeIcons.snapchat, url: 'https://www.snapchat.com/add/rg_5711'),
    ],
  ),
  const TeamMember(
    name: 'Vineet Vikram Rao',
    imagePath: 'assets/VineetVRao.png',
    role: 'CORE DEVELOPER',
    socials: [
      SocialLink(icon: FontAwesomeIcons.instagram, url: 'https://www.instagram.com/vineett.r09'),
      SocialLink(icon: FontAwesomeIcons.github, url: 'https://github.com/galac01389'),
      SocialLink(icon: FontAwesomeIcons.linkedinIn, url: 'https://www.linkedin.com/in/vvrao13'),
    ],
  ),
  const TeamMember(
    name: 'Vipul Kumar',
    imagePath: 'assets/VipulKumar.png',
    role: 'CONTRIBUTOR',
    socials: [
      SocialLink(icon: FontAwesomeIcons.instagram, url: 'https://www.instagram.com/s.i.n.g.h_v?igsh=OGNjbmR2Zm51ZHk3'),
      SocialLink(icon: FontAwesomeIcons.x, url: 'https://x.com/VipulSi97672300'),
    ],
  ),
  const TeamMember(
    name: 'Tribhuvan Pratap Singh',
    imagePath: 'assets/TribhuvanPSingh.png',
    role: 'CONTRIBUTOR',
    socials: [
      SocialLink(icon: FontAwesomeIcons.instagram, url: 'https://www.instagram.com/_kanhaiya.thakur_?igsh=eHJ5N3Mwdms0MG9n'),
      SocialLink(icon: FontAwesomeIcons.linkedinIn, url: 'https://www.linkedin.com/in/tribhu2606?utm_source=share_via&utm_content=profile&utm_medium=member_android'),
      SocialLink(icon: FontAwesomeIcons.github, url: 'https://github.com/TPS06'),
    ],
  ),
  const TeamMember(
    name: 'Vaishnavendra Dhar Dwivedi',
    imagePath: 'assets/VaishnavendraDDiwvedi.png',
    role: 'CONTRIBUTOR',
    socials: [
      SocialLink(icon: FontAwesomeIcons.linkedinIn, url: 'https://www.linkedin.com/in/vaishnavendra-dhar-dwivedi-9b7765248'),
      SocialLink(icon: FontAwesomeIcons.github, url: 'https://github.com/vaishnav-dwivedi'),
    ],
  ),
];

/// Custom spring-like curve for snappy, natural motion
class SpringCurve extends Curve {
  const SpringCurve._();
  
  static const Curve instance = SpringCurve._();
  
  @override
  double transformInternal(double t) {
    // Spring physics - faster start, quick settle
    final c4 = 2.0 * 3.14159 / 3.0;
    if (t == 0) return 0.0;
    if (t == 1) return 1.0;
    return pow(2.0, -10.0 * t) * sin((t * 10.0 - 0.75) * c4) + 1.0;
  }
}

/// Fast easing curve - snappy feel
class FastCurve extends Curve {
  const FastCurve._();
  
  static const Curve instance = FastCurve._();
  
  @override
  double transformInternal(double t) {
    // Fast ease-out - quick transition
    return 1.0 - pow(1.0 - t, 3).toDouble();
  }
}

const Duration _animDuration = Duration(milliseconds: 300);
const Curve _springCurve = SpringCurve.instance;
const Curve _fastCurve = FastCurve.instance;

/// Team Accordion Widget
class TeamAccordion extends StatefulWidget {
  const TeamAccordion({super.key});

  @override
  State<TeamAccordion> createState() => _TeamAccordionState();
}

class _TeamAccordionState extends State<TeamAccordion> {
  int? _expandedIndex;

  void _onTap(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(teamMembers.length, (index) {
        return _TeamMemberTile(
          member: teamMembers[index],
          isExpanded: _expandedIndex == index,
          onTap: () => _onTap(index),
        );
      }),
    );
  }
}

class _TeamMemberTile extends StatelessWidget {
  final TeamMember member;
  final bool isExpanded;
  final VoidCallback onTap;

  const _TeamMemberTile({
    required this.member,
    required this.isExpanded,
    required this.onTap,
  });

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedContainer(
      duration: _animDuration,
      curve: _springCurve,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: primary.withValues(alpha: isExpanded ? 0.4 : 0.15),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: primary.withValues(alpha: 0.12),
                  blurRadius: max(0.01, 20.0), // Ensure non-negative
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            // Using AnimatedCrossFade for smooth content transition
            child: AnimatedCrossFade(
              duration: _animDuration,
              firstCurve: _fastCurve,
              secondCurve: _fastCurve,
              sizeCurve: _springCurve,
              crossFadeState: isExpanded 
                  ? CrossFadeState.showSecond 
                  : CrossFadeState.showFirst,
              firstChild: KeyedSubtree(
                key: const ValueKey('collapsed'),
                child: _buildCollapsedRow(isDark, primary),
              ),
              secondChild: KeyedSubtree(
                key: const ValueKey('expanded'),
                child: _buildExpandedCard(isDark, primary, screenWidth),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedRow(bool isDark, Color primary) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Small circular image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              image: DecorationImage(
                image: AssetImage(member.imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                // Use FaIcon for FontAwesome icons
                Row(
                  children: member.socials.take(3).map((social) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FaIcon(social.icon, size: 12, color: Colors.grey),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Icon(
            Icons.expand_more_rounded,
            color: Colors.grey,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedCard(bool isDark, Color primary, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Large circular profile image - centered
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: _animDuration,
            curve: _springCurve,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: child,
              );
            },
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage(member.imagePath),
                  fit: BoxFit.cover,
                ),
                border: Border.all(
                  color: primary.withValues(alpha: 0.5),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.25),
                    blurRadius: max(0.01, 16.0),
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Name in large text
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: _animDuration,
            curve: _fastCurve,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Text(
              member.name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          // Role badge in cyan/teal color
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF00CED1).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF00CED1).withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Text(
              member.role,
              style: const TextStyle(
                color: Color(0xFF00CED1),
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Divider line
          Container(
            height: 1,
            width: screenWidth * 0.4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  primary.withValues(alpha: 0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Social icons row at bottom - using FaIcon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: member.socials.map((social) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _SocialButton(
                  icon: social.icon,
                  onPressed: () => _launchUrl(social.url),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final FaIconData icon;
  final VoidCallback onPressed;

  const _SocialButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.06) 
                : Colors.black.withValues(alpha: 0.04),
            shape: BoxShape.circle,
          ),
          child: FaIcon(
            icon,
            size: 20,
            color: isDark ? Colors.white70 : Colors.black45,
          ),
        ),
      ),
    );
  }
}