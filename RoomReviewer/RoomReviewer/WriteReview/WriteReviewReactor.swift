//
//  WriteReviewReactor.swift
//  RoomReviewer
//
//  Created by 김상규 on 8/25/25.
//

import UIKit
import ReactorKit
import RxSwift

final class WriteReviewReactor: Reactor {
    private let reviewDBManager: ReviewDBManager
    struct State {
        let media: Media
        var contentType: MediaType
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
        
//        case saveButtonTapped
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
    
    private let dbManager: MediaDBManager
    private let imageProvider: ImageProviding
    
    init(media: Media, dbManager: MediaDBManager, imageProvider: ImageProviding, reviewDBManager: ReviewDBManager) {
        self.initialState = State(media: media, contentType: media.mediaType)
        self.reviewDBManager = reviewDBManager
        self.dbManager = dbManager
        self.imageProvider = imageProvider
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return loadPosterImage(currentState.media.posterPath)
            
        case .ratingChanged(let score):
            return .just(.setRating(score))
            
        case .reviewChanged(let review):
            return .just(.setReview(review))
            
        case .commentChanged(let comment):
            return .just(.setComment(comment))
            
        case .quoteChanged(let quote):
            return .just(.setQuote(quote))
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
        return imageProvider.fetchImage(from: imagePath)
            .map { image in
                return .setPosterImage(image)
            }
    }
}

