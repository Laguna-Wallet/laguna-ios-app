import BigInt
import SoraFoundation

final class AnalyticsRewardsViewModelFactory: AnalyticsViewModelFactoryBase<SubqueryRewardItemData>,
    AnalyticsRewardsViewModelFactoryProtocol {
    override func getHistoryItemTitle(data _: SubqueryRewardItemData, locale: Locale) -> String {
        R.string.localizable.stakingReward(preferredLanguages: locale.rLanguages)
    }

    override func chartDecimalValues(
        _ data: [SubqueryRewardItemData],
        by period: AnalyticsPeriod,
        locale: Locale
    ) -> [AnalyticsSelectedChartData] {
        let dates = data.map(\.date)
        guard let startDate = dates.first, let endDate = dates.last else { return [] }

        let count = period.chartBarsCount(startDate: startDate, endDate: endDate, calendar: calendar)
        let formatter = dateFormatter(period: period, for: locale)

        let dateComponents: Set<Calendar.Component> = {
            switch period {
            case .month:
                return [.year, .month, .day]
            case .week:
                return [.year, .month, .day]
            case .year, .all:
                return [.year, .month]
            }
        }()
        let groupedByDate = data
            .groupedBy(dateComponents: dateComponents, calendar: calendar)
        let sortedByDate: [(Date, [SubqueryRewardItemData])] = groupedByDate.keys
            .map { (key: Date) in
                (key, groupedByDate[key]!)
            }
            .sorted(by: { $0.0 < $1.0 })

        let timestampInterval = period.timestampInterval(startDate: startDate, endDate: endDate, calendar: calendar)
        let distance = timestampInterval.1 - timestampInterval.0
        return (0 ..< count).map { index in
            let portion = distance / Int64(count)
            let cur: Int64 = timestampInterval.0 + Int64(index) * portion
            let date = Date(timeIntervalSince1970: TimeInterval(cur))
            let first = sortedByDate.last(where: { $0.0.timeIntervalSince(date) < TimeInterval(portion) })
            if let tuple = first {
                let dateTitle = formatter.string(from: tuple.0)
                let yValue = tuple.1.map(\.amount)
                    .compactMap { amount in
                        Decimal.fromSubstrateAmount(
                            amount,
                            precision: chain.addressType.precision
                        )
                    }
                    .reduce(0.0, +)

                return AnalyticsSelectedChartData(
                    yValue: yValue,
                    dateTitle: dateTitle,
                    sections: createSections(rewardsData: tuple.1, locale: locale)
                )
            } else {
                return AnalyticsSelectedChartData(
                    yValue: 0,
                    dateTitle: "",
                    sections: []
                )
            }
        }
    }
}

extension SubqueryRewardItemData: AnalyticsViewModelItem {
    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(timestamp))
    }

    static func emptyListDescription(for locale: Locale) -> String {
        R.string.localizable.stakingAnalyticsRewardsEmptyMessage(preferredLanguages: locale.rLanguages)
    }

    var amountInChart: BigUInt {
        amount
    }

    var amountInHistory: BigUInt {
        amount
    }

    var amountSign: FloatingPointSign {
        .plus
    }
}

extension SubqueryRewardItemData: AnalyticsRewardDetailsModel {
    func typeText(locale: Locale) -> String {
        R.string.localizable.stakingRewardDetailsReward(preferredLanguages: locale.rLanguages)
    }
}
