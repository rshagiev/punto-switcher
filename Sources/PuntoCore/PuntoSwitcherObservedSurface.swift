public enum PuntoSwitcherObservedSurface {
    public enum AutoCorrectionCancellingKeys {
        public static let setCancellingKeyStateSelector = "setCancellingKeyState:doEnable:"
        public static let backspaceSelector = "dontAutoconvertWordWithBackspace:"
        public static let deleteSelector = "dontAutoconvertWordWithDelete:"
        public static let leftArrowSelector = "dontAutoconvertWordWithLeftArrow:"
        public static let rightArrowSelector = "dontAutoconvertWordWithRightArrow:"
        public static let upArrowSelector = "dontAutoconvertWordWithUpArrow:"
        public static let downArrowSelector = "dontAutoconvertWordWithDownArrow:"
    }

    public enum UndoLearning {
        public static let setUndoCollectionEnabledSelector = "setUndoCollectionEnabled:"
        public static let setMustShowUndoWindowSelector = "setMustShowUndoWindow:"
        public static let setUndoDictionarySelector = "setUndoDictionary:"
        public static let undoWindowControllerClassName = "UndoWindowController"
        public static let undoWindowDelegateProtocolName = "UndoWindowDelegate"
        public static let undoWindowResourceName = "UndoWindow"
        public static let undoAlertFormatKey = "PMUserRuleUndoAlertFormat"
        public static let showUndoLearningWindowCheckboxChangedSelector = "showUndoLearningWindowCheckboxChanged:"
        public static let undoLearningCheckboxChangedSelector = "undoLearningCheckboxChanged:"
        public static let undoLearningCheckboxKey = "undoLearningCheckbox"
        public static let showUndoLearningWindowCheckboxKey = "showUndoLearningWindowCheckbox"
        public static let undoTriesKey = "undoTries"
        public static let undoPersistsKey = "undoPersists"
        public static let undoWasDoneKey = "undoWasDone"
        public static let undoConvertionSelector = "undoConvertion"
        public static let resetUndoBufferSelector = "resetUndoBuffer"
    }

    public enum UserRules {
        public static let createUserRuleSelector = "createUserRule"
        public static let modifyUserRuleSelector = "modifyUserRule"
        public static let removeUserRuleWithIndexSelector = "removeUserRuleWithIndex:"
        public static let addUserRuleSelector = "addUserRuleWithString:rule:shouldSwitchLayout:isRuleActive:isRegExp:"
        public static let modifyUserRuleWithIndexSelector = "modifyUserRuleWithIndex:string:rule:shouldSwitchLayout:isRuleActive:isRegExp:"
        public static let showWordAddedTooltipSelector = "showWordAddedTooltip:"
    }
}
