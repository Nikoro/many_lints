// ignore_for_file: many_lints/prefer_immediate_return, many_lints/prefer_shorthands_with_enums
// ignore_for_file: unused_local_variable
// prefer_switch_expression
//
// Suggests converting switch statements to switch expressions.
//
// In cases where all branches of a switch statement have a return statement or
// assign to the same variable, using a switch expression can make the code more
// compact and easier to understand.

enum DeliveryStage { packed, shipped, delivered }

enum DeliveryIcon { box, truck, home }

class ExampleService {
  // === BAD examples ===

  // LINT: All cases return a value - use switch expression
  DeliveryIcon iconForBad(DeliveryStage stage) {
    switch (stage) {
      case DeliveryStage.packed:
        return DeliveryIcon.box;
      case DeliveryStage.shipped:
        return DeliveryIcon.truck;
      case DeliveryStage.delivered:
        return DeliveryIcon.home;
    }
  }

  // LINT: All cases assign to the same variable
  String getDescriptionBad(DeliveryIcon icon) {
    String description;
    switch (icon) {
      case DeliveryIcon.box:
        description = 'Waiting in the warehouse';
      case DeliveryIcon.truck:
        description = 'On the road';
      case DeliveryIcon.home:
        description = 'Dropped at the door';
    }
    return description;
  }

  // LINT: Works with default case too
  String getNameBad(int value) {
    switch (value) {
      case 1:
        return 'one';
      case 2:
        return 'two';
      default:
        return 'unknown';
    }
  }

  // === GOOD examples ===

  // GOOD: Using switch expression with return
  DeliveryIcon iconForGood(DeliveryStage stage) {
    return switch (stage) {
      DeliveryStage.packed => DeliveryIcon.box,
      DeliveryStage.shipped => DeliveryIcon.truck,
      DeliveryStage.delivered => DeliveryIcon.home,
    };
  }

  // GOOD: Using switch expression with assignment
  String getDescriptionGood(DeliveryIcon icon) {
    final description = switch (icon) {
      DeliveryIcon.box => 'Waiting in the warehouse',
      DeliveryIcon.truck => 'On the road',
      DeliveryIcon.home => 'Dropped at the door',
    };
    return description;
  }

  // GOOD: Switch expression with default case (using wildcard)
  String getNameGood(int value) {
    return switch (value) {
      1 => 'one',
      2 => 'two',
      _ => 'unknown',
    };
  }

  // === Cases where the lint does NOT trigger ===

  // GOOD: Fallthrough cases (not convertible to expression)
  String getFallthroughResult(int value) {
    switch (value) {
      case 1:
      case 2:
        return 'one or two';
      case 3:
        return 'three';
    }
    return 'unknown';
  }

  // GOOD: Multiple statements per case
  String getWithSideEffect(int value) {
    switch (value) {
      case 1:
        print('Processing one');
        return 'one';
      case 2:
        print('Processing two');
        return 'two';
    }
    return 'unknown';
  }

  // GOOD: Cases without return expressions
  void doSomething(int value) {
    switch (value) {
      case 1:
        print('one');
        return;
      case 2:
        print('two');
        return;
    }
  }

  // GOOD: Mixed assignment targets
  String getMixed(int value) {
    String result = '';
    String other;
    switch (value) {
      case 1:
        result = 'one';
      case 2:
        other = 'two';
    }
    return result;
  }
}

// Example showing the benefits
class ConfigFactory {
  // Without switch expression (verbose)
  String getModeBad(bool isProduction) {
    switch (isProduction) {
      case true:
        return 'production';
      case false:
        return 'development';
    }
  }

  // With switch expression (concise)
  String getModeGood(bool isProduction) {
    return switch (isProduction) {
      true => 'production',
      false => 'development',
    };
  }
}

// Complex example with expressions
class Calculator {
  // BAD: Switch statement with complex expressions
  int calculateBad(int value) {
    switch (value) {
      case 1:
        return value * 2;
      case 2:
        return value + 10;
      case 3:
        return value - 5;
      default:
        return 0;
    }
  }

  // GOOD: Switch expression with complex expressions
  int calculateGood(int value) {
    return switch (value) {
      1 => value * 2,
      2 => value + 10,
      3 => value - 5,
      _ => 0,
    };
  }
}
