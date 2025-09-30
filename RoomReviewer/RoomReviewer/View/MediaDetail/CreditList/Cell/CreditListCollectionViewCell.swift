//
//  CreditListCollectionViewCell.swift
//  RoomReviewer
//
//  Created by 김상규 on 9/29/25.
//

import UIKit
import ReactorKit
import SnapKit
import Then

final class CreditListCollectionViewCell: UICollectionViewCell, View {
    static let cellID = "CreditListCollectionViewCell"
    var disposeBag = DisposeBag()
    
    private let profileImageView = UIImageView().then {
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
        $0.backgroundColor = AppColor.appLightGray
        $0.tintColor = AppColor.appWhite
        $0.layer.borderWidth = 1
        $0.layer.borderColor = AppColor.appWhite.withAlphaComponent(0.3).cgColor
    }
    
    private let nameLabel = UILabel().then {
        $0.font = AppFont.semiboldSubTitle
        $0.textColor = AppColor.appWhite
        $0.textAlignment = .left
    }
    
    private let roleLabel = UILabel().then {
        $0.font = AppFont.subTitle
        $0.textColor = AppColor.appLightGray
        $0.textAlignment = .left
        $0.numberOfLines = 0
    }
    
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureHierarchy() {
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(roleLabel)
        contentView.addSubview(activityIndicator)
    }
    
    private func configureLayout() {
        profileImageView.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(5)
            $0.width.equalTo(profileImageView.snp.height)
            $0.leading.equalTo(contentView)
        }
        
        nameLabel.snp.makeConstraints {
            $0.bottom.equalTo(profileImageView.snp.centerY).inset(-5)
            $0.leading.equalTo(profileImageView.snp.trailing).offset(15)
            $0.trailing.equalTo(contentView).inset(20)
        }
        
        roleLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom)
            $0.leading.equalTo(profileImageView.snp.trailing).offset(15)
            $0.trailing.equalTo(contentView).inset(20)
        }
        
        activityIndicator.snp.makeConstraints {
            $0.center.equalTo(profileImageView)
        }
    }
    
    func bind(reactor: CreditListCollectionViewCellReactor) {
        reactor.state.map { $0.name }
            .observe(on: MainScheduler.instance)
            .bind(to: nameLabel.rx.text)
            .disposed(by: disposeBag)
            
        reactor.state.map { $0.character }
            .observe(on: MainScheduler.instance)
            .bind(to: roleLabel.rx.text)
            .disposed(by: disposeBag)
            
        reactor.state.map { $0.isLoading }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(to: activityIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
            
        reactor.state.map { $0.profileImage }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(to: profileImageView.rx.image)
            .disposed(by: disposeBag)
            
        reactor.state.map { $0.profileImage }
            .distinctUntilChanged()
            .filter { $0 == nil }
            .map { _ in Reactor.Action.loadImage }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        self.profileImageView.image = nil
        self.roleLabel.text = nil
        self.nameLabel.text = nil
        self.reactor = nil
    }
}
