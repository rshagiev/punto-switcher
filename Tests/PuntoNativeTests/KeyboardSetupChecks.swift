@main
enum KeyboardSetupChecks {
    static func main() {
        verify(granted: [], canTap: false, missing: .accessibility, probes: 0)
        verify(granted: [.inputMonitoring], canTap: true, missing: .accessibility, probes: 0)
        verify(granted: [.accessibility], canTap: false, missing: .postEvents, probes: 0)
        verify(granted: [.accessibility, .postEvents], canTap: true, missing: nil, probes: 1)
        verify(granted: [.accessibility, .postEvents], canTap: false, missing: .inputMonitoring, probes: 1)
        verify(granted: [.accessibility, .postEvents, .inputMonitoring], canTap: false, missing: nil, probes: 0)
        print("PASS: requests only the next missing keyboard capability")
    }

    private static func verify(granted: [KeyboardPermission], canTap: Bool,
                               missing: KeyboardPermission?, probes expectedProbes: Int) {
        var probes = 0
        let actual = KeyboardPermission.firstMissing(check: { granted.contains($0) }, canTapKeys: {
            probes += 1
            return canTap
        })
        precondition(actual == missing && probes == expectedProbes,
                     "Unexpected permission step for \(granted), canTap=\(canTap): \(String(describing: actual))")
    }
}
