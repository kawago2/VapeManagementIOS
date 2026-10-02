import SwiftUI

/// Type-safe Hierarchical Localization Keys for VapeCareTracker
/// All keys are dot-notated identifiers mapping to `Localizable.xcstrings`.
enum L10n {
    // MARK: - Common
    enum Common {
        static let cancel = LocalizedStringKey("common.cancel")
        static let save = LocalizedStringKey("common.save")
        static let delete = LocalizedStringKey("common.delete")
        static let edit = LocalizedStringKey("common.edit")
        static let done = LocalizedStringKey("common.done")
        static let ok = LocalizedStringKey("common.ok")
        static let allGood = LocalizedStringKey("common.all_good")
        static let all = LocalizedStringKey("common.all")
        static let days = LocalizedStringKey("common.days")
    }
    
    // MARK: - Dashboard
    enum Dashboard {
        static let title = LocalizedStringKey("dashboard.title")
        static let coilStatus = LocalizedStringKey("dashboard.status.coil")
        static let cottonStatus = LocalizedStringKey("dashboard.status.cotton")
        static let searchPrompt = LocalizedStringKey("dashboard.search_prompt")
        
        static func needsCheck(_ count: Int) -> String {
            String(format: String(localized: "dashboard.status.needs_check %@"), "\(count)")
        }
        
        static func needChange(_ count: Int) -> String {
            String(format: String(localized: "dashboard.status.need_change %@"), "\(count)")
        }
        
        enum Tabs {
            static let overview = LocalizedStringKey("dashboard.tab.all")
            static let tanks = LocalizedStringKey("dashboard.tab.tanks")
            static let batteries = LocalizedStringKey("dashboard.tab.batteries")
            static let liquids = LocalizedStringKey("dashboard.tab.liquids")
        }
        
        enum Sections {
            static let tanks = LocalizedStringKey("dashboard.section.tanks")
            static let batteries = LocalizedStringKey("dashboard.section.batteries")
            static let liquids = LocalizedStringKey("dashboard.section.liquids")
        }
        
        enum Placeholders {
            static let emptyTanks = LocalizedStringKey("dashboard.placeholder.empty_tanks")
            static let emptyBatteries = LocalizedStringKey("dashboard.placeholder.empty_batteries")
            static let emptyLiquids = LocalizedStringKey("dashboard.placeholder.empty_liquids")
            static let noMatchingTanks = LocalizedStringKey("dashboard.placeholder.no_matching_tanks")
            static let noMatchingBatteries = LocalizedStringKey("dashboard.placeholder.no_matching_batteries")
            static let noMatchingLiquids = LocalizedStringKey("dashboard.placeholder.no_matching_liquids")
        }
        
        enum Actions {
            static let addTank = LocalizedStringKey("dashboard.action.add_tank")
            static let addBattery = LocalizedStringKey("dashboard.action.add_battery")
            static let addLiquid = LocalizedStringKey("dashboard.action.add_liquid")
            static let editSetup = LocalizedStringKey("dashboard.action.edit_setup")
            static let deleteTank = LocalizedStringKey("dashboard.action.delete_tank")
            static let quickReplaced = LocalizedStringKey("dashboard.action.quick_replaced")
        }
        
        enum Alerts {
            static let confirmReset = LocalizedStringKey("dashboard.alert.confirm_reset_title")
            static let deleteItem = LocalizedStringKey("dashboard.alert.delete_item_title")
            
            static func resetMessage(target: String, name: String) -> String {
                String(format: String(localized: "dashboard.alert.reset_message %@ %@"), target, name)
            }
            
            static func deleteMessage(name: String) -> String {
                String(format: String(localized: "dashboard.alert.delete_message %@"), name)
            }
        }
    }
    
    // MARK: - Tank Setup Form
    enum TankForm {
        static let addTitle = LocalizedStringKey("tank.form.add_title")
        static let editTitle = LocalizedStringKey("tank.form.edit_title")
        static let identitySection = LocalizedStringKey("tank.form.identity_section")
        static let devicePlaceholder = LocalizedStringKey("tank.form.device_placeholder")
        static let wirePlaceholder = LocalizedStringKey("tank.form.wire_placeholder")
        static let activeLiquid = LocalizedStringKey("tank.form.active_liquid")
        static let noLiquid = LocalizedStringKey("tank.form.no_liquid")
        static let coilSection = LocalizedStringKey("tank.form.coil_section")
        static let coilDate = LocalizedStringKey("tank.form.coil_date")
        static let cottonSection = LocalizedStringKey("tank.form.cotton_section")
        static let cottonDate = LocalizedStringKey("tank.form.cotton_date")
        
        static func coilLimit(_ days: Int) -> String {
            String(format: String(localized: "tank.form.coil_limit %@"), "\(days)")
        }
        static func cottonLimit(_ days: Int) -> String {
            String(format: String(localized: "tank.form.cotton_limit %@"), "\(days)")
        }
    }
    
    // MARK: - Battery Form
    enum BatteryForm {
        static let addTitle = LocalizedStringKey("battery.form.add_title")
        static let editTitle = LocalizedStringKey("battery.form.edit_title")
        static let identitySection = LocalizedStringKey("battery.form.identity_section")
        static let idPlaceholder = LocalizedStringKey("battery.form.id_placeholder")
        static let brandPlaceholder = LocalizedStringKey("battery.form.brand_placeholder")
        static let notesPlaceholder = LocalizedStringKey("battery.form.notes_placeholder")
        static let historySection = LocalizedStringKey("battery.form.history_section")
        static let purchaseDate = LocalizedStringKey("battery.form.purchase_date")
        
        static func lifespanLimit(_ days: Int) -> String {
            String(format: String(localized: "battery.form.lifespan_limit %@"), "\(days)")
        }
    }
    
    // MARK: - Liquid Form
    enum LiquidForm {
        static let addTitle = LocalizedStringKey("liquid.form.add_title")
        static let editTitle = LocalizedStringKey("liquid.form.edit_title")
        static let identitySection = LocalizedStringKey("liquid.form.identity_section")
        static let namePlaceholder = LocalizedStringKey("liquid.form.name_placeholder")
        static let nicPlaceholder = LocalizedStringKey("liquid.form.nic_placeholder")
        static let volumePlaceholder = LocalizedStringKey("liquid.form.volume_placeholder")
        static let historySection = LocalizedStringKey("liquid.form.history_section")
        static let openedDate = LocalizedStringKey("liquid.form.opened_date")
        static let shelfLifeFooter = LocalizedStringKey("liquid.form.shelf_life_footer")
        
        static func shelfLifeLimit(_ days: Int) -> String {
            String(format: String(localized: "liquid.form.shelf_life_limit %@"), "\(days)")
        }
    }
    
    // MARK: - Cloud Settings Sheet
    enum CloudSettings {
        static let title = LocalizedStringKey("cloud.title")
        static let providerHeader = LocalizedStringKey("cloud.provider_header")
        static let serverlessSub = LocalizedStringKey("cloud.serverless_subtitle")
        static let urlHeader = LocalizedStringKey("cloud.url_header")
        static let urlFooter = LocalizedStringKey("cloud.url_footer")
        static let clearUrl = LocalizedStringKey("cloud.clear_url")
        static let tokenHeader = LocalizedStringKey("cloud.token_header")
        static let tokenFooter = LocalizedStringKey("cloud.token_footer")
        static let tokenPlaceholder = LocalizedStringKey("cloud.token_placeholder")
        static let clearToken = LocalizedStringKey("cloud.clear_token")
        static let testButton = LocalizedStringKey("cloud.test_button")
        static let backupHeader = LocalizedStringKey("cloud.backup_header")
        static let backupFooter = LocalizedStringKey("cloud.backup_footer")
        static let exportJson = LocalizedStringKey("cloud.export_json")
        static let exportCsv = LocalizedStringKey("cloud.export_csv")
        static let alertTitle = LocalizedStringKey("cloud.alert_title")
        static let connectSuccess = LocalizedStringKey("cloud.connect_success")
    }
    
    // MARK: - Maintenance History Sheet
    enum History {
        static let title = LocalizedStringKey("history.title")
        static let emptyTitle = LocalizedStringKey("history.empty_title")
        static let emptyDescription = LocalizedStringKey("history.empty_desc")
        static let filterType = LocalizedStringKey("history.filter_type")
        static let filterAll = LocalizedStringKey("history.filter_all")
        static let filterCoil = LocalizedStringKey("history.filter_coil")
        static let filterCotton = LocalizedStringKey("history.filter_cotton")
        static let coilChanged = LocalizedStringKey("history.coil_changed")
        static let cottonChanged = LocalizedStringKey("history.cotton_changed")
        
        static func activityList(_ count: Int) -> String {
            String(format: String(localized: "history.activity_list %@"), "\(count)")
        }
    }
    
    // MARK: - Notifications
    enum Notifications {
        static let cottonTitle = LocalizedStringKey("notification.cotton_title")
        static let coilTitle = LocalizedStringKey("notification.coil_title")
    }
    
    // MARK: - Tools & Calculator
    enum Tools {
        static let title = LocalizedStringKey("tools.title")
        static let parameters = LocalizedStringKey("tools.parameters")
        static let powerWatt = LocalizedStringKey("tools.power_watt")
        static let batteryVolt = LocalizedStringKey("tools.battery_volt")
        static let coilResistance = LocalizedStringKey("tools.coil_resistance")
        static let calculatedResults = LocalizedStringKey("tools.calculated_results")
        static let currentDraw = LocalizedStringKey("tools.current_draw")
        static let safetyWarning = LocalizedStringKey("tools.safety_warning")
        static let coilSpecs = LocalizedStringKey("tools.coil_specs")
        static let targetResistance = LocalizedStringKey("tools.target_resistance")
        static let wireGauge = LocalizedStringKey("tools.wire_gauge")
        static let innerDiameter = LocalizedStringKey("tools.inner_diameter")
        static let recommendation = LocalizedStringKey("tools.recommendation")
        static let estimatedWraps = LocalizedStringKey("tools.estimated_wraps")
        static let setupType = LocalizedStringKey("tools.setup_type")
        static let singleCoil = LocalizedStringKey("tools.single_coil")
        static let footerNote = LocalizedStringKey("tools.footer_note")
    }
}
