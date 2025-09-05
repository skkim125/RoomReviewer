//
//  MyPageHeaderView.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/5/25.
//

import UIKit
import SnapKit

final class MyPageHeaderView: UICollectionReusableView {
    static let reusableID = "MyPageHeaderView"
    
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
            $0.top.horizontalEdges.equalTo(self)
            $0.bottom.equalTo(self).inset(5)
        }
    }
    
    func configureUI(header: String?) {
        titleLabel.text = header
    }
}
