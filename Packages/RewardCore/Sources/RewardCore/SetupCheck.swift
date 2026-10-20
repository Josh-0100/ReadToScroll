public enum SetupCheck {
    /// Counts are apps + web domains picked in each FamilyActivityPicker.
    public static func problems(earnItemCount: Int, spendItemCount: Int) -> [String] {
        var problems: [String] = []
        if earnItemCount == 0 { problems.append("Pick Apple Books as your reading app.") }
        if spendItemCount == 0 { problems.append("Pick Instagram as the app to lock.") }
        return problems
    }
}
