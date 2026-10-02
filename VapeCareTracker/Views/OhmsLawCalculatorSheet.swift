import SwiftUI

struct OhmsLawCalculatorSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    enum CalculationMode: String, CaseIterable, Identifiable {
        case powerAndResistance = "Power & Resistance"
        case voltageAndResistance = "Voltage & Resistance"
        case coilWrap = "Coil Wrap Estimator"
        
        var id: String { rawValue }
    }
    
    @State private var mode: CalculationMode = .powerAndResistance
    
    // Inputs for Power & Resistance
    @State private var wattage: String = "45"
    @State private var resistance: String = "0.3"
    
    // Inputs for Voltage & Resistance
    @State private var voltage: String = "3.7"
    
    // Inputs for Coil Wrap
    @State private var targetResistance: String = "0.4"
    @State private var innerDiameter: Double = 3.0 // 2.5mm or 3.0mm
    @State private var wireGauge: String = "Ni80 26ga" // Ni80, Kanthal A1, SS316L
    
    private let wireGauges = ["Ni80 24ga", "Ni80 26ga", "Ni80 28ga", "Kanthal A1 24ga", "Kanthal A1 26ga", "SS316L 26ga"]
    
    // Computed Values
    private var calculatedCurrent: Double {
        let r = Double(resistance) ?? 0.0
        guard r > 0 else { return 0 }
        if mode == .powerAndResistance {
            let p = Double(wattage) ?? 0.0
            return sqrt(p / r)
        } else {
            let v = Double(voltage) ?? 0.0
            return v / r
        }
    }
    
    private var calculatedVoltageOrPower: (label: String, value: String, unit: String) {
        let r = Double(resistance) ?? 0.0
        guard r > 0 else { return ("Output", "0.0", "") }
        if mode == .powerAndResistance {
            let p = Double(wattage) ?? 0.0
            let v = sqrt(p * r)
            return ("Voltage", String(format: "%.2f", v), "V")
        } else {
            let v = Double(voltage) ?? 0.0
            let p = (v * v) / r
            return ("Power", String(format: "%.1f", p), "W")
        }
    }
    
    private var estimatedWraps: Int {
        let target = Double(targetResistance) ?? 0.4
        // Resistance per mm approx factors
        let resPerMm: Double
        switch wireGauge {
        case "Ni80 24ga": resPerMm = 0.0023
        case "Ni80 26ga": resPerMm = 0.0036
        case "Ni80 28ga": resPerMm = 0.0057
        case "Kanthal A1 24ga": resPerMm = 0.0030
        case "Kanthal A1 26ga": resPerMm = 0.0047
        default: resPerMm = 0.0028 // SS316L
        }
        
        let loopLength = Double.pi * (innerDiameter + 0.4) // include wire thickness
        let wraps = target / (loopLength * resPerMm)
        return max(3, min(12, Int(round(wraps))))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Mode Selector
                Section {
                    Picker("Tool Mode", selection: $mode) {
                        ForEach(CalculationMode.allCases) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                if mode != .coilWrap {
                    // Ohm's Law Calculator
                    Section {
                        if mode == .powerAndResistance {
                            HStack {
                                Text(L10n.Tools.powerWatt)
                                Spacer()
                                TextField("Watt", text: $wattage)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: 80)
                            }
                        } else {
                            HStack {
                                Text(L10n.Tools.batteryVolt)
                                Spacer()
                                TextField("Volt", text: $voltage)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: 80)
                            }
                        }
                        
                        HStack {
                            Text(L10n.Tools.coilResistance)
                            Spacer()
                            TextField("Ohm", text: $resistance)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 80)
                        }
                    } header: {
                        Text(L10n.Tools.parameters)
                    }
                    
                    // Results Card
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L10n.Tools.currentDraw)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.2f A", calculatedCurrent))
                                    .font(.title2.bold())
                                    .foregroundStyle(calculatedCurrent > 25 ? Color.red : (calculatedCurrent > 18 ? Color.orange : Color.green))
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(calculatedVoltageOrPower.label)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(calculatedVoltageOrPower.value) \(calculatedVoltageOrPower.unit)")
                                    .font(.title2.bold())
                                    .foregroundStyle(Color.primary)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        // Safety Note
                        if calculatedCurrent > 20 {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text(L10n.Tools.safetyWarning)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text(L10n.Tools.calculatedResults)
                    }
                } else {
                    // Coil Wrap Estimator
                    Section {
                        HStack {
                            Text(L10n.Tools.targetResistance)
                            Spacer()
                            TextField("Ohm", text: $targetResistance)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 80)
                        }
                        
                        Picker(L10n.Tools.wireGauge, selection: $wireGauge) {
                            ForEach(wireGauges, id: \.self) { g in
                                Text(g).tag(g)
                            }
                        }
                        
                        Picker(L10n.Tools.innerDiameter, selection: $innerDiameter) {
                            Text("2.5 mm").tag(2.5)
                            Text("3.0 mm").tag(3.0)
                            Text("3.5 mm").tag(3.5)
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text(L10n.Tools.coilSpecs)
                    }
                    
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L10n.Tools.estimatedWraps)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("~ \(estimatedWraps) Wraps")
                                    .font(.title2.bold())
                                    .foregroundStyle(Color.blue)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(L10n.Tools.setupType)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(L10n.Tools.singleCoil)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text(L10n.Tools.recommendation)
                    } footer: {
                        Text(L10n.Tools.footerNote)
                    }
                }
            }
            .navigationTitle(L10n.Tools.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.Common.done) {
                        dismiss()
                    }
                    .font(.body.bold())
                }
            }
        }
    }
}
