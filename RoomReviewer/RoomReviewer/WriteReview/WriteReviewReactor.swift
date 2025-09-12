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
        let mediaObjectID: NSManagedObjectID
        let title: String
        let posterPath: String?
//        var contentType: MediaType
        var posterImage: UIImage?
        var rating: Double = 0
        var review: String = ""
        var comment: String = ""
        var quote: String = ""
        var isSaving: Bool = false
        var canSave: Bool = false
        @Pulse var shouldDismiss: Void?
    }
    
    enum Action {
        case viewDidLoad
        case ratingChanged(Double)
        case reviewChanged(String)
        case commentChanged(String)
        case quoteChanged(String)
        case saveButtonTapped
    }
    
    enum Mutation {
        case setPosterImage(UIImage?)
        case setRating(Double)
        case setReview(String)
        case setQuote(String)
        case setComment(String)
        case setSaving(Bool)
        case dismissView
    }
    
    var initialState: State
    
    private let imageProvider: ImageProviding
    private let mediaDBManager: MediaDBManager
    private let reviewDBManager: ReviewDBManager
    
    init(mediaObjectID: NSManagedObjectID, title: String, posterPath: String?, imageProvider: ImageProviding, mediaDBManager: MediaDBManager, reviewDBManager: ReviewDBManager) {
        self.initialState = State(mediaObjectID: mediaObjectID, title: title, posterPath: posterPath)
        self.imageProvider = imageProvider
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
            return saveReview(mediaObjectID: state.mediaObjectID, rating: state.rating, review: state.review, comment: state.comment, quote: state.quote)
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
        }
        
        newState.canSave = !newState.review.isEmpty && newState.rating > 0
        
        return newState
    }
    
    private func loadPosterImage(_ imagePath: String?) -> Observable<Mutation> {
        return imageProvider.fetchImage(urlString: imagePath)
            .map { .setPosterImage($0) }
    }
    
    private func saveReview(mediaObjectID: NSManagedObjectID, rating: Double, review: String, comment: String?, quote: String?) -> Observable<Mutation> {
        return reviewDBManager.createReview(mediaObjectID, rating: rating, review: review, comment: comment, quote: quote)
            .asObservable()
            .map { reviewID in
                return .dismissView
            }
    }
}
