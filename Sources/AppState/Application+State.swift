extension Application {
    public struct State<Value> {
        private var _value: Value
        public var value: Value {
            get {
                guard 
                    let value = shared.cache.get(
                        scope.key,
                        as: Value.self
                    )
                else { return _value }

                return value
            }
            set {
                _value = newValue
                shared.cache.set(
                    value: newValue,
                    forKey: scope.key
                )
            }
        }

        let scope: Scope

        init(
            initial value: Value,
            scope: Scope
        ) {
            self._value = value
            self.scope = scope
        }
    }
}
