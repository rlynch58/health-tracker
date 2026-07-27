import Foundation
import SwiftData

/// A single logged meal. `dateKey` is the authoritative day it belongs to
/// (see `DateKey` / ARCHITECTURE_NOTES.md §1) -- decided once at write time
/// and never re-derived from `loggedAt`. `loggedAt` is only for ordering
/// meals within a day.
///
/// CLOUDKIT: every stored property is optional or has a default value, and
/// there are no unique constraints, per the CloudKit-compatible schema rules.
///
/// CLAMPING: the six macro fields are backed by private, unclamped storage
/// and exposed only through computed properties that clamp on write. This
/// makes an out-of-range value structurally unwritable -- there is no public
/// stored property to assign past the ceiling, unlike the web app, where
/// clamping was bolted onto each save call site and one was missed in v1.40.
/// `didSet` was deliberately not used: SwiftData's `@Model` macro rewrites
/// stored properties into its own persistence-backed accessors, and
/// `didSet` observers on those rewritten properties are not reliably
/// invoked. A private stored property with a public computed wrapper avoids
/// the macro's property rewriting entirely for the public-facing name, since
/// only the private `_` property is ever seen by SwiftData as a model
/// property -- the computed property is plain Swift with no macro
/// involvement.
@Model
final class Meal {
    var id: UUID = UUID()
    var dateKey: String = ""
    var loggedAt: Date = Date()
    var name: String = ""

    @Attribute(.externalStorage) var photo: Data?

    private var _calories: Int?
    private var _protein: Int?
    private var _carbs: Int?
    private var _fat: Int?
    private var _sodium: Int?
    private var _sugar: Int?

    var calories: Int? {
        get { _calories }
        set { _calories = newValue.map { Limits.clamp($0, max: Limits.maxCaloriesEntry) } }
    }
    var protein: Int? {
        get { _protein }
        set { _protein = newValue.map { Limits.clamp($0, max: Limits.maxProteinEntry) } }
    }
    var carbs: Int? {
        get { _carbs }
        set { _carbs = newValue.map { Limits.clamp($0, max: Limits.maxCarbsEntry) } }
    }
    var fat: Int? {
        get { _fat }
        set { _fat = newValue.map { Limits.clamp($0, max: Limits.maxFatEntry) } }
    }
    var sodium: Int? {
        get { _sodium }
        set { _sodium = newValue.map { Limits.clamp($0, max: Limits.maxSodium) } }
    }
    var sugar: Int? {
        get { _sugar }
        set { _sugar = newValue.map { Limits.clamp($0, max: Limits.maxSugarEntry) } }
    }

    init(
        dateKey: String,
        loggedAt: Date = Date(),
        name: String = "",
        calories: Int? = nil,
        protein: Int? = nil,
        carbs: Int? = nil,
        fat: Int? = nil,
        sodium: Int? = nil,
        sugar: Int? = nil,
        photo: Data? = nil
    ) {
        self.id = UUID()
        self.dateKey = dateKey
        self.loggedAt = loggedAt
        self.name = name
        self.photo = photo
        // Routed through the clamped setters above.
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.sodium = sodium
        self.sugar = sugar
    }
}
