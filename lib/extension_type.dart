extension type Mapper._(({String b}) _) {}

/// Описываем поля модели и их типы
typedef ButtonItemScheme = ({String label, int icon, String? press});

/// Расш
extension type const ButtonItem._(ButtonItemScheme scheme) {
  const ButtonItem(String label, int icon, String? press)
    : this._((label: label, icon: icon, press: press));
}

enum Body {
  first('');

  final String boy;

  const Body(this.boy);
}

extension type const BodyItem._(Body item) {
  const BodyItem(Body item) : this._(item);
}

void main() {
  final l = const ButtonItem('label', 12, null);

  final (icon, label) = (l.scheme.icon, l.scheme.label);

  print('$label $icon');
}
