import Foundation

/// One row of the fixed 1662 30-day Psalter cycle: which psalms are appointed for a given
/// day-of-month at a given office. Decoded from `Resources/Psalter/psalter_cycle.json`.
struct PsalterCycleEntry: Decodable {
    /// 1...30. There is no separate entry for the 31st — per the Psalter's rubric, the 31st day
    /// uses the same psalms as the 30th.
    let day: Int
    let office: Office
    /// Psalm numbers appointed for this day/office, in reading order. A long psalm (e.g. 119) can
    /// appear across several consecutive day/office entries, since it's read across multiple
    /// offices rather than repeated in full each time.
    let psalms: [Int]
}
