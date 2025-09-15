//
//  WriteReviewViewController.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/25/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import Cosmos
import SnapKit
import Then

final class WriteReviewViewController: UIViewController, View {
    var disposeBag = DisposeBag()
    private var activeTextInput: UIView?

    private let scrollView = UIScrollView()
    
    private let contentView = UIView()
    
    deinit {
        print("WriteReviewViewController deinit")
    }
    
    private let posterImageView = UIImageView().then {
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
        $0.backgroundColor = AppColor.appDarkGray
        $0.layer.borderWidth = 0.3
        $0.layer.borderColor = AppColor.appWhite.withAlphaComponent(0.3).cgColor
    }
    
    private let titleLabel = UILabel().then {
        $0.font = AppFont.boldLargeTitle
        $0.numberOfLines = 0
        $0.textAlignment = .center
    }
    
    private let ratingSectionTitle = UILabel().then {
        $0.text = "별점 매기기"
        $0.font = AppFont.boldTitle
    }
    private let ratingView = CosmosView().then {
        var setting = CosmosSettings()
        setting.fillMode = .half
        setting.totalStars = 5
        setting.starSize = 40
        setting.minTouchRating = 0
        setting.starMargin = 5
        setting.emptyBorderWidth = 2
        setting.filledBorderWidth = 2
        setting.emptyBorderColor = .systemYellow
        setting.filledBorderColor = .systemYellow
        setting.filledColor = .systemYellow
        
        $0.settings = setting
        $0.rating = 0
    }
    
    private let reviewTitleLabel = UILabel().then {
        $0.text = "한줄평 작성하기"
        $0.font = AppFont.boldTitle
    }
    private let reviewTextField = UITextField().then {
        $0.font = AppFont.subTitle
        $0.backgroundColor = .secondarySystemBackground
        $0.layer.cornerRadius = 8
        $0.placeholder = "ex) 시리즈의 결정판이나 동전 던지기는 진부해"
        
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: $0.frame.height))
        $0.leftView = padding
        $0.leftViewMode = .always
        $0.rightView = padding
        $0.rightViewMode = .always
    }
    
    private let commentTitleLabel = UILabel().then {
        $0.text = "상세한 코멘트 남기기"
        $0.font = AppFont.boldTitle
    }
    private let reviewDetailTextView = UITextView().then {
        $0.font = AppFont.subTitle
        $0.backgroundColor = .secondarySystemBackground
        $0.layer.cornerRadius = 8
        $0.textContainerInset = UIEdgeInsets(top: 10, left: 5, bottom: 10, right: 5)
    }
    private let reviewDetailPlaceholderLabel = UILabel().then {
        $0.text = "한줄평으로 부족하다면 코멘트를 추가하세요(선택)"
        $0.font = AppFont.subTitle
        $0.textColor = .placeholderText
        $0.isUserInteractionEnabled = false
    }
    
    private let quoteTitleaLabel = UILabel().then {
        $0.text = "내가 뽑은 명대사"
        $0.font = AppFont.boldTitle
    }
    private let quoteTextField = UITextField().then {
        $0.font = AppFont.subTitle
        $0.backgroundColor = .secondarySystemBackground
        $0.layer.cornerRadius = 8
        $0.placeholder = "ex) 호의가 계속되면 그게 권리인 줄 알아(선택)"
        $0.isUserInteractionEnabled = true
        
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: $0.frame.height))
        $0.leftView = padding
        $0.leftViewMode = .always
        $0.rightView = padding
        $0.rightViewMode = .always
    }
    
    private let saveButton = UIButton(type: .system).then {
        $0.titleLabel?.font = AppFont.boldTitle
        $0.backgroundColor = .systemRed
        $0.setTitleColor(AppColor.appWhite, for: .normal)
        $0.setTitleColor(AppColor.appGray, for: .disabled)
        $0.layer.cornerRadius = 12
        $0.isEnabled = false
    }
    
    var updateReviewHandler: (() -> Void)?
    
    private let imageProvider: ImageProviding
    private let imageFileManager: ImageFileManaging
    
    init(imageProvider: ImageProviding, imageFileManager: ImageFileManaging) {
        self.imageProvider = imageProvider
        self.imageFileManager = imageFileManager
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let editButton = UIBarButtonItem(title: "수정", style: .plain, target: nil, action: nil).then {
        $0.tintColor = AppColor.appWhite
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.appBackgroundColor
        
        configureHierarchy()
        configureLayout()
        configureNavigationBar()
        setupKeyboardDismissal()
    }
    
    private let dismissButton = UIBarButtonItem().then {
        $0.image = UIImage(systemName: "chevron.left")
        $0.tintColor = AppColor.appWhite
        $0.style = .done
        $0.target = nil
        $0.action = nil
    }
    
    private func configureNavigationBar() {
        self.navigationItem.leftBarButtonItem = dismissButton
    }
    
    func bind(reactor: WriteReviewReactor) {
        bindState(reactor: reactor)
        bindAction(reactor: reactor)
    }
    
    private func bindState(reactor: WriteReviewReactor) {
        reactor.state.map { $0.title }
            .asDriver(onErrorJustReturn: nil)
            .drive(titleLabel.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.posterImage }
            .asDriver(onErrorJustReturn: nil)
            .drive(with: self) { owner, image in
                if let image = image {
                    owner.posterImageView.image = image
                } else {
                    owner.posterImageView.backgroundColor = AppColor.appDarkGray
                }
            }
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.canSave }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(with: self) { owner, canSave in
                owner.saveButton.isEnabled = canSave
                owner.saveButton.backgroundColor = canSave ? .systemRed : AppColor.appLightGray
            }
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$shouldDismiss)
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: ())
            .drive(with: self) { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.rating }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: 0)
            .drive(with: self) { owner, rating in
                owner.ratingView.rating = rating
            }
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.review }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "")
            .drive(reviewTextField.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.comment }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: nil)
            .drive(reviewDetailTextView.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.quote }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: nil)
            .drive(quoteTextField.rx.text)
            .disposed(by: disposeBag)
        
        reactor.state
            .map { ($0.isEditMode, $0.reviewEntity != nil) }
            .distinctUntilChanged { $0 == $1 }
            .asDriver(onErrorJustReturn: (false, false))
            .drive(with: self) { owner, state in
                let (isEditMode, hasReview) = state
                
                owner.ratingView.isUserInteractionEnabled = isEditMode
                owner.reviewTextField.isUserInteractionEnabled = isEditMode
                owner.reviewDetailTextView.isUserInteractionEnabled = isEditMode
                owner.quoteTextField.isUserInteractionEnabled = isEditMode
                
                if hasReview {
                    owner.editButton.title = isEditMode ? "취소" : "수정"
                    owner.navigationItem.title = isEditMode ? "평론 수정" : "나의 평론"
                    owner.navigationItem.rightBarButtonItem = owner.editButton
                } else {
                    owner.navigationItem.title = "평론 작성하기"
                    owner.navigationItem.rightBarButtonItem = nil
                }
                
                owner.scrollView.snp.remakeConstraints {
                    $0.top.horizontalEdges.equalTo(owner.view.safeAreaLayoutGuide)
                    
                    if isEditMode {
                        $0.bottom.equalTo(owner.saveButton.snp.top).offset(-10)
                    } else {
                        $0.bottom.equalTo(owner.view.safeAreaLayoutGuide)
                    }
                }
            }
            .disposed(by: disposeBag)
        
        reactor.state
            .map { state -> (isHidden: Bool, title: String) in
                let isHidden = !state.isEditMode
                let title: String
                
                if state.reviewEntity != nil {
                    title = "수정하기"
                } else {
                    title = "평론 작성하기"
                }
                return (isHidden, title)
            }
            .asDriver(onErrorJustReturn: (isHidden: true, title: ""))
            .drive(with: self) { owner, buttonState in
                owner.saveButton.setTitle(buttonState.title, for: .normal)
                owner.saveButton.isHidden = buttonState.isHidden
            }
            .disposed(by: disposeBag)
    }
    
    private func bindAction(reactor: WriteReviewReactor) {
        reactor.action.onNext(.viewDidLoad)
        
        ratingView.didTouchCosmos = { [weak self] rating in
            guard let self = self else { return }
            self.reactor?.action.onNext(.ratingChanged(rating))
        }
        
        reviewTextField.rx.text.orEmpty
            .map(Reactor.Action.reviewChanged)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        reviewDetailTextView.rx.text.orEmpty
            .map(Reactor.Action.commentChanged)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        reviewDetailTextView.rx.text.orEmpty
            .map { !$0.isEmpty }
            .asDriver(onErrorJustReturn: false)
            .drive(reviewDetailPlaceholderLabel.rx.isHidden)
            .disposed(by: disposeBag)
        
        quoteTextField.rx.text.orEmpty
            .map(Reactor.Action.quoteChanged)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        saveButton.rx.tap
            .map { _ in
                return Reactor.Action.saveButtonTapped
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        editButton.rx.tap
            .bind(with: self) { owner, _ in
                if owner.reactor?.currentState.isEditMode == true {
                    owner.reactor?.action.onNext(.cancelButtonTapped)
                } else {
                    owner.reactor?.action.onNext(.editButtonTapped)
                }
            }
            .disposed(by: disposeBag)
        
        dismissButton.rx.tap
            .asDriver()
            .drive(with: self) { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
        
        let keyboardWillShow = NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
            .compactMap { notification -> (frame: CGRect, duration: TimeInterval)? in
                guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                      let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return nil }
                return (frame, duration)
            }

        let keyboardWillHide = NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
            .compactMap { notification -> TimeInterval? in
                return notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
            }

        keyboardWillShow
            .bind(with: self) { owner, info in
                let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: info.frame.height, right: 0)
                owner.scrollView.contentInset = contentInset
                owner.scrollView.scrollIndicatorInsets = contentInset
                
                if owner.reactor?.currentState.isEditMode == true {
                    owner.saveButton.snp.remakeConstraints {
                        $0.horizontalEdges.equalTo(owner.view.safeAreaLayoutGuide).inset(20)
                        $0.bottom.equalToSuperview().inset(info.frame.height + 10)
                        $0.height.equalTo(50)
                    }
                }
                
                UIView.animate(withDuration: info.duration) {
                    owner.view.layoutIfNeeded()
                    if let activeField = owner.activeTextInput, activeField == owner.reviewDetailTextView {
                        owner.scrollView.scrollRectToVisible(activeField.frame, animated: false)
                    }
                }
            }
            .disposed(by: disposeBag)

        keyboardWillHide
            .bind(with: self) { owner, duration in
                owner.scrollView.contentInset = .zero
                owner.scrollView.scrollIndicatorInsets = .zero
                
                if owner.reactor?.currentState.isEditMode == true {
                    owner.saveButton.snp.remakeConstraints {
                        $0.horizontalEdges.equalTo(owner.view.safeAreaLayoutGuide).inset(20)
                        $0.bottom.equalTo(owner.view.safeAreaLayoutGuide).inset(10)
                        $0.height.equalTo(50)
                    }
                }
                
                UIView.animate(withDuration: duration) {
                    owner.view.layoutIfNeeded()
                }
            }
            .disposed(by: disposeBag)
    }
    
    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension WriteReviewViewController {
    private func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(posterImageView)
        contentView.addSubview(titleLabel)
        
        contentView.addSubview(ratingSectionTitle)
        contentView.addSubview(ratingView)
        
        contentView.addSubview(reviewTitleLabel)
        contentView.addSubview(reviewTextField)
        
        contentView.addSubview(commentTitleLabel)
        contentView.addSubview(reviewDetailTextView)
        contentView.addSubview(reviewDetailPlaceholderLabel)
        
        contentView.addSubview(quoteTitleaLabel)
        contentView.addSubview(quoteTextField)
        
        view.addSubview(saveButton)
    }
    
    private func configureLayout() {
        scrollView.snp.makeConstraints {
            $0.top.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView)
            $0.width.equalTo(scrollView)
        }
        
        posterImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(view.bounds.width/3)
            $0.height.equalTo(posterImageView.snp.width).multipliedBy(1.5)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(posterImageView.snp.bottom).offset(15)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }
        
        ratingSectionTitle.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(15)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }
        
        ratingView.snp.makeConstraints {
            $0.top.equalTo(ratingSectionTitle.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
        }
        
        reviewTitleLabel.snp.makeConstraints {
            $0.top.equalTo(ratingView.snp.bottom).offset(20)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }
        
        reviewTextField.snp.makeConstraints {
            $0.top.equalTo(reviewTitleLabel.snp.bottom).offset(10)
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.height.equalTo(37)
        }
        
        commentTitleLabel.snp.makeConstraints {
            $0.top.equalTo(reviewTextField.snp.bottom).offset(25)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }
        
        reviewDetailTextView.snp.makeConstraints {
            $0.top.equalTo(commentTitleLabel.snp.bottom).offset(10)
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.height.equalTo(100)
        }
        
        reviewDetailPlaceholderLabel.snp.makeConstraints {
            $0.top.equalTo(reviewDetailTextView.snp.top).offset(10)
            $0.leading.equalTo(reviewDetailTextView.snp.leading).offset(10)
        }
        
        quoteTitleaLabel.snp.makeConstraints {
            $0.top.equalTo(reviewDetailTextView.snp.bottom).offset(25)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }
        
        quoteTextField.snp.makeConstraints {
            $0.top.equalTo(quoteTitleaLabel.snp.bottom).offset(10)
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.height.equalTo(37)
            $0.bottom.equalTo(contentView.snp.bottom).inset(20)
        }
        
        saveButton.snp.makeConstraints {
            $0.horizontalEdges.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(10)
            $0.height.equalTo(50)
        }
    }
}

extension WriteReviewViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Allow touches on UIControl subclasses (buttons, textfields, etc.)
        if touch.view is UIControl {
            return false
        }
        // Allow touches on the text view
        if touch.view == self.reviewDetailTextView || touch.view?.isDescendant(of: self.reviewDetailTextView) == true {
            return false
        }
        // Allow touches on the rating view
        if touch.view == self.ratingView || touch.view?.isDescendant(of: self.ratingView) == true {
            return false
        }
        return true
    }
}
