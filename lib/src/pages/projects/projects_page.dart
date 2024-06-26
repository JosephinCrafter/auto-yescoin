import 'package:ahl/src/widgets/widgets.dart';
import 'package:flutter/material.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  static const String routeName = '/projects';

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AhlAppBar(),
      body: Center(
        child: Text(
          'Project Space',
          style: Theme.of(context).textTheme.displayLarge,
        ),
      ),
    );
  }
}
