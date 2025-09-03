//
//  CreditsSectionHeader.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/1/25.
//

import UIKit

final class CreditsSectionHeader: UICollectionReusableView {
    static let reusableID = "CreditsSectionHeader"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.boldLargeTitle
        label.textColor = AppColor.appWhite
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func configureHierarchy() {
        addSubview(titleLabel)
    }
    
    private func configureLayout() {
        titleLabel.snp.makeConstraints {
            $0.edges.equalTo(self)
        }
    }
    
    func configureUI(header: String?) {
        titleLabel.text = header
    }
}
