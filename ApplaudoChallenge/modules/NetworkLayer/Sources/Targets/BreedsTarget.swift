//
//  BreedsTarget.swift
//  NetworkLayer
//
//  Created by Alfredo Fregoso on 15/09/26.
//

import Moya

enum BreedsTarget {
    case getBreeds(page: Int, limit: Int)
}

extension BreedsTarget: NetworkingTargetType {
    var requestPath: String {
        switch self {
        case .getBreeds: return "breeds"
        }
    }

    var requestMethod: RequestMethod {
        switch self {
        case .getBreeds: return .get
        }
    }

    var task: Moya.Task {
        switch self {
        case .getBreeds(let page, let limit):
            return .requestParameters(
                parameters: ["limit": limit, "page": page],
                encoding: URLEncoding.queryString
            )
        }
    }
}
