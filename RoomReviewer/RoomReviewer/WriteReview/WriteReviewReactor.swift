//
//  WriteReviewReactor.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/25/25.
//

import UIKit
import ReactorKit
import RxSwift
import CoreData

final class WriteReviewReactor: Reactor {
    struct State {
        let media: Media
        let title: String
        let posterPath: String?
        var reviewEntity: ReviewEntity?
        var posterImage: UIImage?
        var rating: Double
        var review: String
        var comment: String?
        var quote: String?
        var isSaving: Bool = false
        var canSave: Bool = false
        var isEditMode: Bool
        
        let initialRating: Double
        let initialReview: String
        let initialComment: String?
        let initialQuote: String?
        
        @Pulse var shouldDismiss: Void?
    }
    
    enum Action {
        case viewDidLoad
        case ratingChanged(Double)
        case reviewChanged(String)
        case commentChanged(String)
        case quoteChanged(String)
        case saveButtonTapped
        case editButtonTapped
        case cancelButtonTapped
    }
    
    enum Mutation {
        case setPosterImage(UIImage?)
        case setRating(Double)
        case setReview(String)
        case setQuote(String?)
        case setComment(String?)
        case setSaving(Bool)
        case dismissView
        case setEditMode(Bool)
        case revertToInitialState
        case setReviewEntity(ReviewEntity?)
    }
    
    var initialState: State
    
    private let imageFileManager: ImageFileManaging
    private let mediaDBManager: MediaDBManager
    private let reviewDBManager: ReviewDBManager
    
    init(media: Media, review: ReviewEntity?, imageFileManager: ImageFileManaging, mediaDBManager: MediaDBManager, reviewDBManager: ReviewDBManager) {
        if let existingReview = review {
            self.initialState = State(
                media: media,
                title: media.title,
                posterPath: media.posterPath,
                reviewEntity: existingReview,
                rating: existingReview.rating,
                review: existingReview.review,
                comment: existingReview.comment,
                quote: existingReview.quote,
                isEditMode: false,
                initialRating: existingReview.rating,
                initialReview: existingReview.review,
                initialComment: existingReview.comment,
                initialQuote: existingReview.quote
            )
        } else {
            self.initialState = State(
                media: media,
                title: media.title,
                posterPath: media.posterPath,
                reviewEntity: nil,
                rating: 0,
                review: "",
                comment: nil,
                quote: nil,
                isEditMode: true,
                initialRating: 0,
                initialReview: "",
                initialComment: nil,
                initialQuote: nil
            )
        }
        self.imageFileManager = imageFileManager
        self.mediaDBManager = mediaDBManager
        self.reviewDBManager = reviewDBManager
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return loadPosterImage(currentState.posterPath)
            
        case .ratingChanged(let score):
            return .just(.setRating(score))
            
        case .reviewChanged(let review):
            return .just(.setReview(review))
            
        case .commentChanged(let comment):
            return .just(.setComment(comment))
            
        case .quoteChanged(let quote):
            return .just(.setQuote(quote))
            
        case .saveButtonTapped:
            let state = currentState
            if let reviewEntity = state.reviewEntity {
                return reviewDBManager.updateReview(reviewEntity.objectID, rating: state.rating, review: state.review, comment: state.comment, quote: state.quote)
                    .asObservable()
                    .map { .setEditMode(false) }
            } else {
                return createReview(mediaID: state.media.id, rating: state.rating, review: state.review, comment: state.comment, quote: state.quote)
            }
            
        case .editButtonTapped:
            return .just(.setEditMode(true))
            
        case .cancelButtonTapped:
            return .just(.revertToInitialState)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setRating(let score):
            newState.rating = score
        case .setSaving(let isSaving):
            newState.isSaving = isSaving
        case .dismissView:
            newState.shouldDismiss = ()
        case .setPosterImage(let image):
            newState.posterImage = image
        case .setReview(let review):
            newState.review = review
        case .setQuote(let quote):
            newState.quote = quote
        case .setComment(let comment):
            newState.comment = comment
        case .setEditMode(let isEditMode):
            newState.isEditMode = isEditMode
        case .revertToInitialState:
            newState.isEditMode = false
            newState.rating = newState.initialRating
            newState.review = newState.initialReview
            newState.comment = newState.initialComment
            newState.quote = newState.initialQuote
        case .setReviewEntity(let reviewEntity):
            newState.reviewEntity = reviewEntity
        }
        
        newState.canSave = !newState.review.isEmpty && newState.rating > 0
        
        return newState
    }
    
    private func loadPosterImage(_ imagePath: String?) -> Observable<Mutation> {
        return imageFileManager.loadImage(urlString: imagePath)
            .map { image in
                return .setPosterImage(image)
            }
    }
    
    private func createReview(mediaID: Int, rating: Double, review: String, comment: String?, quote: String?) -> Observable<Mutation> {
        return reviewDBManager.createReview(mediaID, rating: rating, review: review, comment: comment, quote: quote)
            .asObservable()
            .flatMap { [weak self] reviewID -> Observable<Mutation> in
                guard let self = self else { return .empty() }
                let reviewEntity = self.reviewDBManager.fetchReview(id: mediaID)
                return .concat([
                    .just(.setReviewEntity(reviewEntity)),
                    .just(.setEditMode(false))
                ])
            }
    }
}
