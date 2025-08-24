//
//  CreditsCollectionVIewCell.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/21/25.
//

import UIKit
import ReactorKit
import SnapKit
import Then

final class CreditsCollectionViewCell: UICollectionViewCell, View {
    static let cellID = "CreditsCollectionViewCell"
    var disposeBag = DisposeBag()
    
    private let profileImageView = UIImageView().then {
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
        $0.backgroundColor = .systemGray3
        $0.tintColor = .white
    }
    
    private let nameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .semibold)
        $0.textColor = .white
        $0.textAlignment = .center
    }
    
    private let characterLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = .lightGray
        $0.textAlignment = .center
        $0.numberOfLines = 1
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
        contentView.addSubview(characterLabel)
        contentView.addSubview(activityIndicator)
    }
    
    private func configureLayout() {
        profileImageView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
            $0.height.equalTo(profileImageView.snp.width).multipliedBy(1.2)
        }
        
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(profileImageView.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(5)
        }
        
        characterLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(2)
            $0.leading.trailing.equalTo(nameLabel)
        }
        
        activityIndicator.snp.makeConstraints {
            $0.center.equalTo(profileImageView)
        }
    }
    
    func configureCell(reactor: CreditsCollectionViewCellReactor) {
        self.reactor = reactor
    }
    
    func bind(reactor: CreditsCollectionViewCellReactor) {
        reactor.state.map { $0.name }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(to: nameLabel.rx.text)
            .disposed(by: disposeBag)
            
        reactor.state.map { $0.character }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(to: characterLabel.rx.text)
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
            .map { _ in CreditsCollectionViewCellReactor.Action.loadImage }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        self.reactor = nil
    }
}
