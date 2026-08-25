import Foundation
import XCTest
@testable import TokenQuotaCore

final class CompletionsUsageModelsTests: XCTestCase {
    func decodesBucketsResultsAndPagination() throws {
        let json = #"""
        {
          "object": "page",
          "data": [
            {
              "object": "bucket",
              "start_time": 1730419200,
              "end_time": 1730505600,
              "results": [
                {
                  "object": "organization.usage.completions.result",
                  "input_tokens": 1000,
                  "output_tokens": 500,
                  "input_cached_tokens": 800,
                  "num_model_requests": 5,
                  "project_id": "proj_abc",
                  "user_id": null,
                  "api_key_id": "key_abc",
                  "model": "gpt-4o-mini",
                  "batch": false,
                  "service_tier": "default"
                }
              ]
            }
          ],
          "has_more": true,
          "next_page": "page_AAAA"
        }
        """#

        let page = try JSONDecoder().decode(
            CompletionsUsagePage.self,
            from: Data(json.utf8)
        )

        XCTAssertEqual(page.object, "page")
        XCTAssertTrue(page.hasMore)
        XCTAssertEqual(page.nextPage, "page_AAAA")
        XCTAssertEqual(page.data.count, 1)

        let bucket = try XCTUnwrap(page.data.first)
        XCTAssertEqual(bucket.startTime, 1_730_419_200)
        XCTAssertEqual(bucket.endTime, 1_730_505_600)

        let result = try XCTUnwrap(bucket.results.first)
        XCTAssertEqual(result.inputTokens, 1_000)
        XCTAssertEqual(result.outputTokens, 500)
        XCTAssertEqual(result.inputCachedTokens, 800)
        XCTAssertEqual(result.numModelRequests, 5)
        XCTAssertEqual(result.projectID, "proj_abc")
        XCTAssertEqual(result.apiKeyID, "key_abc")
        XCTAssertEqual(result.model, "gpt-4o-mini")
        XCTAssertFalse(result.batch ?? true)
        XCTAssertEqual(result.serviceTier, "default")
    }

    func optionalCachedTokenCountDefaultsToZero() throws {
        let json = #"""
        {
          "object": "page",
          "data": [{
            "object": "bucket",
            "start_time": 10,
            "end_time": 20,
            "results": [{
              "object": "organization.usage.completions.result",
              "input_tokens": 7,
              "output_tokens": 3,
              "num_model_requests": 1
            }]
          }],
          "has_more": false,
          "next_page": null
        }
        """#

        let page = try JSONDecoder().decode(
            CompletionsUsagePage.self,
            from: Data(json.utf8)
        )

        XCTAssertEqual(page.data[0].results[0].inputCachedTokens, 0)
        XCTAssertNil(page.nextPage)
    }
}
