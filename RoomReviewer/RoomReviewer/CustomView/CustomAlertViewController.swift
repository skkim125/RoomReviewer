//
//  CustomAlertViewController.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/19/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

enum AlertButtonType {
    case oneButton
    case twoButton
}

final class CustomAlertViewController: UIViewController {
    typealias CompletionHandler = () -> Void
    private var confirmAction: CompletionHandler?
    private let disposeBag = DisposeBag()
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let entireStackView = UIStackView()
    private let contentStackView = UIStackView()
    private let buttonStackView = UIStackView()
    
    private let customContentView: UIView?
    
    private lazy var confirmButton = CommonButton(title: "확인", foregroundColor: .white, backgroundColor: .systemBlue)
    private lazy var cancelButton = CommonButton(title: "취소", foregroundColor: .white, backgroundColor: .lightGray)

    init(title: String, subtitle: String? = nil, buttonType: AlertButtonType, contentView: UIView? = nil, confirmAction: CompletionHandler? = nil) {
        self.customContentView = contentView
        self.confirmAction = confirmAction
        super.init(nibName: nil, bundle: nil)
        
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
        
        configureContent(title: title, subtitle: subtitle, buttonType: buttonType)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureHierarchy()
        configureLayout()
        configureView()
        bind()
    }
    
    private func configureHierarchy() {
        view.addSubview(containerView)
        containerView.addSubview(entireStackView)
        
        entireStackView.addArrangedSubview(contentStackView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(subtitleLabel)
        
        if let customView = self.customContentView {
            entireStackView.addArrangedSubview(customView)
        }
        
        entireStackView.addArrangedSubview(buttonStackView)
        buttonStackView.addArrangedSubview(cancelButton)
        buttonStackView.addArrangedSubview(confirmButton)
    }
    
    private func configureLayout() {
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(20)
            make.top.greaterThanOrEqualToSuperview().offset(20)
            make.bottom.lessThanOrEqualToSuperview().offset(-20)
        }
        
        entireStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(15)
        }
    }
    
    private func configureView() {
        self.view.backgroundColor = .black.withAlphaComponent(0.4)
        
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true
        
        entireStackView.axis = .vertical
        entireStackView.spacing = 16
        
        contentStackView.axis = .vertical
        contentStackView.spacing = 8
        
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 10
        
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center
    }
    
    private func configureContent(title: String, subtitle: String?, buttonType: AlertButtonType) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        
        if subtitle == nil {
            subtitleLabel.isHidden = true
        }
        
        if buttonType == .oneButton {
            cancelButton.isHidden = true
        }
    }
    
    private func bind() {
        confirmButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.dismiss(animated: true) {
                    owner.confirmAction?()
                }
            }
            .disposed(by: disposeBag)
        
        cancelButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }
}
