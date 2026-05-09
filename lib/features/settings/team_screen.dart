import 'package:flutter/material.dart';
import '../../components/team_member_card.dart';
import '../../components/team_accordion.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('The Team', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: false,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisSpacing: 20,
          childAspectRatio: 0.85,
        ),
        itemCount: teamMembers.length,
        itemBuilder: (context, index) {
          return TeamMemberCard(member: teamMembers[index]);
        },
      ),
    );
  }
}
