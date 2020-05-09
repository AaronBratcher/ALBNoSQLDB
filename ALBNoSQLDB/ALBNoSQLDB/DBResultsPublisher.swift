//
//  DBResultsPublisher.swift
//  ALBNoSQLDB
//
//  Created by Aaron Bratcher on 4/30/20.
//  Copyright © 2020 Aaron Bratcher. All rights reserved.
//

import Foundation
import Combine

protocol UpdatablePublisher {
	var id: UUID { get }
	var table: DBTable { get }
	var conditions: [DBCondition]? { get }
	var validateObjects: Bool { get }

	func updateSubject()
	func clearResults(in table: DBTable)
}

public class DBResultsPublisher<T: DBObject>: UpdatablePublisher, Identifiable {
	public typealias Output = DBResults<T>
	public typealias Failure = DBError

	public let id = UUID()
	let table: DBTable
	let conditions: [DBCondition]?
	let validateObjects: Bool

	private let subject: CurrentValueSubject<DBResults<T>, Failure>
	private var subscriptions = 0
	private let db: ALBNoSQLDB
	private let sortOrder: String?
	private var queryToken: DBCommandToken?

	init(db: ALBNoSQLDB, table: DBTable, sortOrder: String? = nil, conditions: [DBCondition]? = nil, validateObjects: Bool = false) {
		self.db = db
		self.table = table
		self.sortOrder = sortOrder
		self.conditions = conditions
		self.validateObjects = validateObjects
		subject = CurrentValueSubject(DBResults(db: db, keys: []))
	}

	deinit {
		stopPublisher()
	}

	func stopPublisher() {
		queryToken?.cancel()
		db.removePublisher(self)
	}
}

extension DBResultsPublisher: Publisher {
	public func receive<S>(subscriber: S)
	where S: Subscriber, DBResultsPublisher.Failure == S.Failure, DBResultsPublisher.Output == S.Input {
		var start = false

		objc_sync_enter(self)
		subscriptions += 1
		start = subscriptions == 1
		objc_sync_exit(self)

		if start {
			updateSubject()
		}
		DBResultsSubscription(fetchPublisher: self, subscriber: AnySubscriber(subscriber))
	}

	func updateSubject() {
		queryToken = db.keysInTable(T.table, sortOrder: sortOrder, conditions: conditions, validateObjects: validateObjects, queue: DispatchQueue.global(qos: .background)) { [weak self] (results) in
			guard let self = self else { return }

			switch results {
			case .success(let keys):
				let result = DBResults<T>(db: self.db, keys: keys)
				self.subject.send(result)

			case .failure(let error):
				self.subject.send(completion: .failure(error))
			}
		}
	}

	func clearResults(in table: DBTable) {
		if T.table != table { return }

		let result = DBResults<T>(db: self.db, keys: [])
		self.subject.send(result)
	}

	private func dropSubscription() {
		objc_sync_enter(self)
		subscriptions -= 1
		let stop = subscriptions == 0
		objc_sync_exit(self)

		if stop {
			stopPublisher()
		}
	}

	private class DBResultsSubscription: Subscription {
		private var publisher: DBResultsPublisher?
		private var cancellable: AnyCancellable?

		@discardableResult
		init(fetchPublisher: DBResultsPublisher, subscriber: AnySubscriber<Output, Failure>) {
			self.publisher = fetchPublisher

			subscriber.receive(subscription: self)

			cancellable = fetchPublisher.subject.sink(receiveCompletion: { completion in
				subscriber.receive(completion: completion)
			}, receiveValue: { value in
				_ = subscriber.receive(value)
			})
		}

		func request(_ demand: Subscribers.Demand) { }

		func cancel() {
			cancellable?.cancel()
			cancellable = nil
			publisher?.dropSubscription()
			publisher = nil
		}
	}
}
