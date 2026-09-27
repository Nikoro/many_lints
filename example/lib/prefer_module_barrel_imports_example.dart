// prefer_module_barrel_imports: the first import bypasses the module entry point.
import 'barrel_demo/model.dart' as direct;
import 'barrel_demo/barrel_demo.dart' as public;

direct.DemoUser? directUser;
public.DemoUser? publicUser;
