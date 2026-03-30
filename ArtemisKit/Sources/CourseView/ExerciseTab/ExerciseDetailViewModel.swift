//
//  ExerciseDetailViewModel.swift
//
//
//  Created by Nityananda Zbil on 14.06.24.
//

import Common
import Foundation
import SharedModels
import SharedServices
import UserStore

@Observable
final class ExerciseDetailViewModel {
    let courseId: Int
    let exerciseId: Int

    var exercise: DataState<Exercise>
    var problemStatementRendered: DataState<String> = .loading
    var channel: DataState<Channel> = .loading

    var isFeedbackPresented = false
    var latestResultId: Int?
    var participationId: Int?

    // MARK: Web view
    var isWebViewLoading = true
    var webViewHeight = CGFloat.s

    private let exerciseService: ExerciseService
    private let userSession: UserSession

    init(
        courseId: Int,
        exerciseId: Int,
        exercise: DataState<Exercise>,
        exerciseService: ExerciseService = ExerciseServiceFactory.shared,
        userSession: UserSession = UserSessionFactory.shared
    ) {
        self.courseId = courseId
        self.exerciseId = exerciseId
        
        self.exercise = exercise
        
        self.exerciseService = exerciseService
        self.userSession = userSession
    }
    
    func loadExercise() async {
        if let exercise = exercise.value {
            setParticipationAndResultId(from: exercise)
        } else {
            await refreshExercise()
        }
    }
    
    func refreshExercise() async {
        exercise = await exerciseService.getExercise(exerciseId: exerciseId)
        if let exercise = exercise.value {
            setParticipationAndResultId(from: exercise)
        }
    }

    func loadRenderedProblemStatement() async {
        if exercise.value?.baseExercise.problemStatement == nil {
            await refreshExercise()
        }
        guard let problemStatement = exercise.value?.baseExercise.problemStatement else {
            problemStatementRendered = .done(response: "") // Empty problem statement
            return
        }
        // TODO: Web request
            // swiftlint:disable line_length
            problemStatementRendered = .done(response: """
                    <html>
                    <head>
                    <meta name="viewport" content="width=device-width">
                    </head>
                    <body>
                    <style>
                    .artemis-problem-statement{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","Helvetica Neue",Arial,sans-serif;line-height:1.5;color:var(--body-color,#212529)}
                    .artemis-problem-statement h1,.artemis-problem-statement h2,.artemis-problem-statement h3,.artemis-problem-statement h4{font-weight:400}
                    .artemis-problem-statement ol,.artemis-problem-statement ul{margin-bottom:.75em}
                    .artemis-problem-statement hr{border:none;border-top:1px solid var(--border-color,#dee2e6);margin:16px 0}
                    .artemis-problem-statement svg{max-width:100%;height:auto}
                    .artemis-problem-statement a{color:var(--link-color,#3e8acc)}
                    .artemis-problem-statement pre{background:var(--artemis-pre-background,#f5f5f5);color:var(--artemis-pre-color,#333);border:1px solid var(--artemis-pre-border,#ccc);border-radius:4px;padding:10px;font-size:13px;line-height:1.43;white-space:pre-wrap;overflow-wrap:break-word}
                    .artemis-problem-statement :not(pre)>code{font-size:87.5%;color:#d63384;padding:2px 4px;background:var(--artemis-pre-background,#f5f5f5);border-radius:4px}
                    .artemis-problem-statement blockquote{color:var(--markdown-preview-blockquote,#6a737d);border-left:4px solid var(--markdown-preview-blockquote-border,#dfe2e5);padding:0 1em;margin:0 0 16px}
                    .artemis-problem-statement img{max-width:100%}
                    .artemis-task{cursor:pointer;font-weight:600}
                    i.fa.artemis-icon-success,i.fa.artemis-icon-fail{display:inline-block;width:1em;height:1em;vertical-align:-0.125em;background-size:contain;background-repeat:no-repeat}
                    i.fa.artemis-icon-success{background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3E%3Ccircle cx='8' cy='8' r='7.5' fill='%2328a745'/%3E%3Cpath d='M5 8l2 2 4-4' stroke='%23fff' stroke-width='1.5' stroke-linecap='round' stroke-linejoin='round' fill='none'/%3E%3C/svg%3E")}
                    i.fa.artemis-icon-fail{background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3E%3Ccircle cx='8' cy='8' r='7.5' fill='%23dc3545'/%3E%3Cpath d='M5.5 5.5l5 5M10.5 5.5l-5 5' stroke='%23fff' stroke-width='1.5' stroke-linecap='round' fill='none'/%3E%3C/svg%3E")}
                    .artemis-task-stats{font-weight:400;font-size:.9em;margin-left:4px;text-decoration:underline}
                    .artemis-task-success .artemis-task-stats{color:var(--success,#28a745)}
                    .artemis-task-fail .artemis-task-stats{color:var(--danger,#dc3545)}
                    .artemis-task-not-executed .artemis-task-stats{color:var(--secondary,#6c757d)}
                    .markdown-alert{border-left:4px solid var(--info,#17a2b8);padding:8px 16px;margin:16px 0;border-radius:0 4px 4px 0}
                    .markdown-alert-title{font-weight:600}
                    .artemis-problem-statement table{border-collapse:collapse;width:100%}
                    .artemis-problem-statement table th,.artemis-problem-statement table td{border:1px solid var(--border-color,#dee2e6);padding:8px}
                    </style>
                    <div class="artemis-problem-statement"><h1>Sorting with the Strategy Pattern</h1>
                    <p>In this exercise, we want to implement sorting algorithms and choose them based on runtime specific variables.</p>
                    <h3>Part 1: Sorting</h3>
                    <p>First, we need to implement two sorting algorithms, in this case <code>MergeSort</code> and <code>BubbleSort</code>.</p>
                    <p><strong>You have the following tasks:</strong></p>
                    <ol>
                     <li>
                      <p><span class="artemis-task" data-task-name="Implement Bubble Sort" data-test-ids="">Implement Bubble Sort</span>
                       <br>
                       Implement the method <code>performSort(List&lt;Date&gt;)</code> in the class <code>BubbleSort</code>. Make sure to follow the Bubble Sort algorithm exactly.</p>
                     </li>
                     <li>
                      <p><span class="artemis-task" data-task-name="Implement Merge Sort" data-test-ids="">Implement Merge Sort</span>
                       <br>
                       Implement the method <code>performSort(List&lt;Date&gt;)</code> in the class <code>MergeSort</code>. Make sure to follow the Merge Sort algorithm exactly.</p>
                     </li>
                    </ol>
                    <h3>Part 2: Strategy Pattern</h3>
                    <p>We want the application to apply different algorithms for sorting a <code>List</code> of <code>Date</code> objects. Use the strategy pattern to select the right sorting algorithm at runtime.</p>
                    <p><strong>You have the following tasks:</strong></p>
                    <ol>
                     <li>
                      <p><span class="artemis-task artemis-task-not-executed" data-task-name="SortStrategy Interface" data-test-ids="3182,3187" data-test-status="not-executed" data-feedback="[]"><i class="fa fa-times-circle artemis-icon-fail"></i> SortStrategy Interface <span class="artemis-task-stats">0 of 2 tests passed</span></span>
                       <br>
                       Create a <code>SortStrategy</code> interface and adjust the sorting algorithms so that they implement this interface.</p>
                     </li>
                     <li>
                      <p><span class="artemis-task artemis-task-not-executed" data-task-name="Context Class" data-test-ids="3180,3185" data-test-status="not-executed" data-feedback="[]"><i class="fa fa-times-circle artemis-icon-fail"></i> Context Class <span class="artemis-task-stats">0 of 2 tests passed</span></span>
                       <br>
                       Create and implement a <code>Context</code> class following the below class diagram</p>
                     </li>
                     <li>
                      <p><span class="artemis-task artemis-task-not-executed" data-task-name="Context Policy" data-test-ids="3184,3179,3186" data-test-status="not-executed" data-feedback="[]"><i class="fa fa-times-circle artemis-icon-fail"></i> Context Policy <span class="artemis-task-stats">0 of 3 tests passed</span></span>
                       <br>
                       Create and implement a <code>Policy</code> class following the below class diagram with a simple configuration mechanism:</p>
                      <ol>
                       <li>
                        <p><span class="artemis-task artemis-task-not-executed" data-task-name="Select MergeSort" data-test-ids="3181,3190" data-test-status="not-executed" data-feedback="[]"><i class="fa fa-times-circle artemis-icon-fail"></i> Select MergeSort <span class="artemis-task-stats">0 of 2 tests passed</span></span>
                         <br>
                         Select <code>MergeSort</code> when the List has more than 10 dates.</p>
                       </li>
                       <li>
                        <p><span class="artemis-task artemis-task-not-executed" data-task-name="Select BubbleSort" data-test-ids="3183,3188" data-test-status="not-executed" data-feedback="[]"><i class="fa fa-times-circle artemis-icon-fail"></i> Select BubbleSort <span class="artemis-task-stats">0 of 2 tests passed</span></span>
                         <br>
                         Select <code>BubbleSort</code> when the List has less or equal 10 dates.</p>
                       </li>
                      </ol>
                     </li>
                     <li>
                      <p>Complete the <code>Client</code> class which demonstrates switching between two strategies at runtime.</p>
                     </li>
                    </ol>
                    <div class="artemis-diagram" data-diagram-id="uml-1">
                     <?plantuml 1.2026.2?><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" contentStyleType="text/css" data-diagram-type="CLASS" height="311px" preserveAspectRatio="xMidYMid meet" style="" version="1.1" viewBox="0 0 1258 311" width="1258px" zoomAndPan="magnify"><defs/><g><!--class Client--><g class="entity" data-qualified-name="Client" data-source-line="14" id="ent0002"><rect fill="#FFFFFF" height="32" rx="2.5" ry="2.5" style="stroke:#000000;stroke-width:0.5;" width="78.3203" x="141.5" y="7"/><ellipse cx="156.5" cy="23" fill="#ADD1B2" rx="11" ry="11" style="stroke:#181818;stroke-width:1;"/><path d="M159.4688,28.6406 Q158.8906,28.9375 158.25,29.0781 Q157.6094,29.2344 156.9063,29.2344 Q154.4063,29.2344 153.0781,27.5938 Q151.7656,25.9375 151.7656,22.8125 Q151.7656,19.6875 153.0781,18.0313 Q154.4063,16.375 156.9063,16.375 Q157.6094,16.375 158.25,16.5313 Q158.9063,16.6875 159.4688,16.9844 L159.4688,19.7031 Q158.8438,19.125 158.25,18.8594 Q157.6563,18.5781 157.0313,18.5781 Q155.6875,18.5781 155,19.6563 Q154.3125,20.7188 154.3125,22.8125 Q154.3125,24.9063 155,25.9844 Q155.6875,27.0469 157.0313,27.0469 Q157.6563,27.0469 158.25,26.7813 Q158.8438,26.5 159.4688,25.9219 L159.4688,28.6406 Z " fill="#000000"/><text fill="#000000" font-family="sans-serif" font-size="16" lengthAdjust="spacing" textLength="46.3203" x="170.5" y="28.5391">Client</text></g><!--class Policy--><g class="entity" data-qualified-name="Policy" data-source-line="17" id="ent0003"><rect fill="#FFFFFF" height="58.625" rx="2.5" ry="2.5" style="stroke:#000000;stroke-width:0.5;" width="113.4141" x="7" y="113"/><ellipse cx="37.6691" cy="129" fill="#ADD1B2" rx="11" ry="11" style="stroke:#181818;stroke-width:1;"/><path d="M40.6379,134.6406 Q40.0598,134.9375 39.4191,135.0781 Q38.7785,135.2344 38.0754,135.2344 Q35.5754,135.2344 34.2473,133.5938 Q32.9348,131.9375 32.9348,128.8125 Q32.9348,125.6875 34.2473,124.0313 Q35.5754,122.375 38.0754,122.375 Q38.7785,122.375 39.4191,122.5313 Q40.0754,122.6875 40.6379,122.9844 L40.6379,125.7031 Q40.0129,125.125 39.4191,124.8594 Q38.8254,124.5781 38.2004,124.5781 Q36.8566,124.5781 36.1691,125.6563 Q35.4816,126.7188 35.4816,128.8125 Q35.4816,130.9063 36.1691,131.9844 Q36.8566,133.0469 38.2004,133.0469 Q38.8254,133.0469 39.4191,132.7813 Q40.0129,132.5 40.6379,131.9219 L40.6379,134.6406 Z " fill="#000000"/><text fill="#000000" font-family="sans-serif" font-size="16" lengthAdjust="spacing" textLength="46.5938" x="55.1512" y="134.5391">Policy</text><line style="stroke:#000000;stroke-width:0.5;" x1="8" x2="119.4141" y1="145" y2="145"/><text fill="#808080" font-family="sans-serif" font-size="16" lengthAdjust="spacing" textLength="101.4141" x="13" y="163.8516">+configure()</text></g><!--class Context--><g class="entity" data-qualified-name="Context" data-source-line="21" id="ent0004"><rect fill="#FFFFFF" height="85.25" rx="2.5" ry="2.5" style="stroke:#000000;stroke-width:0.5;" width="165.6875" x="216.5" y="100"/><ellipse cx="263.6133" cy="116" fill="#ADD1B2" rx="11" ry="11" style="stroke:#181818;stroke-width:1;"/><path d="M266.582,121.6406 Q266.0039,121.9375 265.3633,122.0781 Q264.7227,122.2344 264.0195,122.2344 Q261.5195,122.2344 260.1914,120.5938 Q258.8789,118.9375 258.8789,115.8125 Q258.8789,112.6875 260.1914,111.0313 Q261.5195,109.375 264.0195,109.375 Q264.7227,109.375 265.3633,109.5313 Q266.0195,109.6875 266.582,109.9844 L266.582,112.7031 Q265.957,112.125 265.3633,111.8594 Q264.7695,111.5781 264.1445,111.5781 Q262.8008,111.5781 262.1133,112.6563 Q261.4258,113.7188 261.4258,115.8125 Q261.4258,117.9063 262.1133,118.9844 Q262.8008,120.0469 264.1445,120.0469 Q264.7695,120.0469 265.3633,119.7813 Q265.957,119.5 266.582,118.9219 L266.582,121.6406 Z " fill="#000000"/><text fill="#000000" font-family="sans-serif" font-size="16" lengthAdjust="spacing" textLength="62.9609" x="284.1133" y="121.5391">Context</text><line style="stroke:#000000;stroke-width:0.5;" x1="217.5" x2="381.1875" y1="132" y2="132"/><text fill="#808080" font-family="sans-serif" font-size="16" lengthAdjust="spacing" textLength="153.6875" x="222.5" y="150.8516">-dates: List&lt;Date&gt;</text><line style="stroke:#000000;stroke-width:0.5;" x1="217.5" x2="381.1875" y1="158.625" y2="158.625"/><text fill="#808080" font-family="sans-serif" font-size="16" lengthAdjust="spacing" textLength="56.8672" x="222.5" y="177.4766">+sort()</text></g><!--class SortStrategy--><g class="entity" data-qualified-name="SortStrategy" data-source-line="26" id="ent0005"><rect fill="#FFFFFF" height="58.625" rx="2.5" ry="2.5" style="stroke:#000000;stroke-width:0.5;" width="227.875" x="528.5" y="113"/><ellipse cx="587.5117" cy="129" fill="#B4A7E5" rx="11" ry="11" style="stroke:#181818;stroke-width:1;"/><path d="M583.4336,124.7656 L583.4336,122.6094 L590.8242,122.6094 L590.8242,124.7656 L588.3555,124.7656 L588.3555,132.8438 L590.8242,132.8438 L590.8242,135 L583.4336,135 L583.4336,132.8438 L585.9023,132.8438 L585.9023,124.7656 L583.4336,124.7656 Z " fill="#000000"/><text fill="#000000" font-family="sans-serif" font-size="16" font-style="italic" lengthAdjust="spacing" textLength="101.3516" x="608.0117" y="134.5391">SortStrategy</text><line style="stroke:#000000;stroke-width:0.5;" x1="529.5" x2="755.375" y1="145" y2="145"/><text fill="#808080" font-family="sans-serif" font-size="16" lengthAdjust="spacing" textLength="215.875" x="534.5" y="163.8516">+performSort(List&lt;Date&gt;)</text></g><!--class BubbleSort--><g class="entity" data-qualified-name="BubbleSort" data-source-line="30" id="ent0006"><rect fill="#FFFFFF" height="58.625" rx="2.5" ry="2.5" style="stroke:#000000;stroke-width:0.5;" width="596.125" x="30.5" y="246"/><ellipse cx="280.0547" cy="262" fill="#ADD1B2" rx="11" ry="11" style="stroke:#181818;stroke-width:1;"/><path d="M283.0234,267.6406 Q282.4453,267.9375 281.8047,268.0781 Q281.1641,268.2344 280.4609,268.2344 Q277.9609,268.2344 276.6328,266.5938 Q275.3203,264.9375 275.3203,261.8125 Q275.3203,258.6875 276.6328,257.0313 Q277.9609,255.375 280.4609,255.375 Q281.1641,255.375 281.8047,255.5313 Q282.4609,255.6875 283.0234,255.9844 L283.0234,258.7031 Q282.3984,258.125 281.8047,257.8594 Q281.2109,257.5781 280.5859,257.5781 Q279.2422,257.5781 278.5547,258.6563 Q277.8672,259.7188 277.8672,261.8125 Q277.8672,263.9063 278.5547,264.9844 Q279.2422,266.0469 280.5859,266.0469 Q281.2109,266.0469 281.8047,265.7813 Q282.3984,265.5 283.0234,264.9219 L283.0234,267.6406 Z " fill="#000000"/><text fill="#000000" font-family="sans-serif" font-size="16" lengthAdjust="spacing" textLength="88.5156" x="300.5547" y="267.5391">BubbleSort</text><line style="stroke:#000000;stroke-width:0.5;" x1="31.5" x2="625.625" y1="278" y2="278"/><text fill="#000000" font-family="sans-serif" font-size="16" lengthAdjust="spacing" textLength="584.125" x="36.5" y="296.8516">&lt;color:testsColor(testBubbleSort())&gt;+performSort(List&lt;Date&gt;)&lt;/color&gt;</text></g><!--class MergeSort--><g class="entity" data-qualified-name="MergeSort" data-source-line="34" id="ent0007"><rect fill="#FFFFFF" height="58.625" rx="2.5" ry="2.5" style="stroke:#000000;stroke-width:0.5;" width="590.6328" x="661" y="246"/><ellipse cx="910.5547" cy="262" fill="#ADD1B2" rx="11" ry="11" style="stroke:#181818;stroke-width:1;"/><path d="M913.5234,267.6406 Q912.9453,267.9375 912.3047,268.0781 Q911.6641,268.2344 910.9609,268.2344 Q908.4609,268.2344 907.1328,266.5938 Q905.8203,264.9375 905.8203,261.8125 Q905.8203,258.6875 907.1328,257.0313 Q908.4609,255.375 910.9609,255.375 Q911.6641,255.375 912.3047,255.5313 Q912.9609,255.6875 913.5234,255.9844 L913.5234,258.7031 Q912.8984,258.125 912.3047,257.8594 Q911.7109,257.5781 911.0859,257.5781 Q909.7422,257.5781 909.0547,258.6563 Q908.3672,259.7188 908.3672,261.8125 Q908.3672,263.9063 909.0547,264.9844 Q909.7422,266.0469 911.0859,266.0469 Q911.7109,266.0469 912.3047,265.7813 Q912.8984,265.5 913.5234,264.9219 L913.5234,267.6406 Z " fill="#000000"/><text fill="#000000" font-family="sans-serif" font-size="16" lengthAdjust="spacing" textLength="83.0234" x="931.0547" y="267.5391">MergeSort</text><line style="stroke:#000000;stroke-width:0.5;" x1="662" x2="1250.6328" y1="278" y2="278"/><text fill="#000000" font-family="sans-serif" font-size="16" lengthAdjust="spacing" textLength="578.6328" x="667" y="296.8516">&lt;color:testsColor(testMergeSort())&gt;+performSort(List&lt;Date&gt;)&lt;/color&gt;</text></g><!--reverse link SortStrategy to MergeSort--><g class="link" data-entity-1="ent0005" data-entity-2="ent0007" data-link-type="extension" data-source-line="38" id="lnk9"><path codeLine="38" d="M727.633,179.0187 C780.143,200.9187 835.65,224.08 888.13,245.97" fill="none" id="SortStrategy-backto-MergeSort" style="stroke:#808080;stroke-width:1;"/><polygon fill="none" points="711.02,172.09,725.3235,184.5564,729.9426,173.481,711.02,172.09" style="stroke:#808080;stroke-width:1;"/></g><!--reverse link SortStrategy to BubbleSort--><g class="link" data-entity-1="ent0005" data-entity-2="ent0006" data-link-type="extension" data-source-line="39" id="lnk11"><path codeLine="39" d="M557.367,179.0187 C504.857,200.9187 449.35,224.08 396.87,245.97" fill="none" id="SortStrategy-backto-BubbleSort" style="stroke:#808080;stroke-width:1;"/><polygon fill="none" points="573.98,172.09,555.0574,173.481,559.6765,184.5564,573.98,172.09" style="stroke:#808080;stroke-width:1;"/></g><!--link Policy to Context--><g class="link" data-entity-1="ent0003" data-entity-2="ent0004" data-link-type="dependency" data-source-line="40" id="lnk12"><path codeLine="40" d="M120.03,142.5 C148.8,142.5 178.34,142.5 210.18,142.5" fill="none" id="Policy-to-Context" style="stroke:#808080;stroke-width:1;"/><polygon fill="#808080" points="216.18,142.5,207.18,138.5,211.18,142.5,207.18,146.5,216.18,142.5" style="stroke:#808080;stroke-width:1;"/><text fill="#000000" font-family="sans-serif" font-size="16" lengthAdjust="spacing" textLength="60.5859" x="138.25" y="135.3516">context</text></g><!--link Context to SortStrategy--><g class="link" data-entity-1="ent0004" data-entity-2="ent0005" data-link-type="dependency" data-source-line="41" id="lnk13"><path codeLine="41" d="M382.53,142.5 C426.35,142.5 474.77,142.5 522.49,142.5" fill="none" id="Context-to-SortStrategy" style="stroke:#808080;stroke-width:1;"/><polygon fill="#808080" points="528.49,142.5,519.49,138.5,523.49,142.5,519.49,146.5,528.49,142.5" style="stroke:#808080;stroke-width:1;"/><text fill="#000000" font-family="sans-serif" font-size="16" lengthAdjust="spacing" textLength="109.3359" x="401" y="135.3516">sortAlgorithm</text></g><!--link Client to Policy--><g class="link" data-entity-1="ent0002" data-entity-2="ent0003" data-link-type="dependency" data-source-line="42" id="lnk14"><path codeLine="42" d="M165.2,39.36 C146.75,57.9 119.5534,85.2082 96.5134,108.3482" fill="none" id="Client-to-Policy" style="stroke:#000000;stroke-width:1;stroke-dasharray:7,7;"/><polygon fill="#000000" points="92.28,112.6,101.4647,109.0446,95.8079,109.0568,95.7956,103.4,92.28,112.6" style="stroke:#000000;stroke-width:1;"/></g><!--link Client to Context--><g class="link" data-entity-1="ent0002" data-entity-2="ent0004" data-link-type="dependency" data-source-line="43" id="lnk15"><path codeLine="43" d="M196.06,39.36 C211.56,54.66 231.7703,74.6246 253.0303,95.6146" fill="none" id="Client-to-Context" style="stroke:#000000;stroke-width:1;stroke-dasharray:7,7;"/><polygon fill="#000000" points="257.3,99.83,253.7058,90.6604,253.7419,96.3171,248.0852,96.3533,257.3,99.83" style="stroke:#000000;stroke-width:1;"/></g><?plantuml-src bLFBRjim43oRNx503xRHAdLpoC4m1DWf2XH8WGB-0bfSIOjGeh5SmNMJ_7j9sf4LEq4JdPQpCxF3XyPZM6bFXRPs3vsdjWAf4GoMkhCIwmQ_mAOJs25eOrAtSORAe15ohOUINPDWmMPhjQ276XcLylVKRZNh1fRCRlV3jRAclmZVRWOjNslZTd5kgQt7GQUmslkb25COZpyBroRrx9m23mh2rzjVpz9wfOlxYbtNcbjd7SEk9i7KwJs7YKOhnmRvmDtO85QZ57k8F2br67bh2Li9atlajxDKx5EMHH4byufndtyEiKkgEiR9TF4rDVA1JGY0V-H2bPbuZ7Eu8o-Bxw7EU-sPlNSiBvqfM7Af2uHrwAs5Wxnw9TWsi1mtaJGvpNabvAhRR2n6tj0av1EVpcOIonDfCfr-mFmNSlK_xvxpNkkJQTPjiyVyvKbyYljNWrszJJfUQiPKrPBb_NsbxXoAmr8zmptlqceEyQQMjd9CKZVg-82kmjjlh_BZwpb7ZxvArMGGmjybUoW9hV53f46fNO3-0G00?></g></svg>
                    </div>
                    <h3>Part 3: Optional Challenges</h3>
                    <p>(These are not tested)</p>
                    <ol>
                     <li>
                      <p>Create a new class <code>QuickSort</code> that implements <code>SortStrategy</code> and implement the Quick Sort algorithm.</p>
                     </li>
                     <li>
                      <p>Make the method <code>performSort(List&lt;Dates&gt;)</code> generic, so that other objects can also be sorted by the same method. <strong>Hint:</strong> Have a look at Java Generics and the interface <code>Comparable</code>.</p>
                     </li>
                     <li>
                      <p>Think about a useful decision in <code>Policy</code> when to use the new <code>QuickSort</code> algorithm.</p>
                     </li>
                    </ol></div>
                    """)
    }

    func loadAssociatedChannel() async {
        channel = await ExerciseChannelServiceFactory.shared.getAssociatedChannel(for: exerciseId, in: courseId)
    }

    private func setParticipationAndResultId(from exercise: Exercise) {
        isWebViewLoading = true

        let participation = exercise.getSpecificStudentParticipation(testRun: false)
        participationId = participation?.id
        // The latest result is the first rated result in the sorted array (=newest)
        if let latestResultId = exercise.baseExercise.latestRatedResult?.id {
            self.latestResultId = latestResultId
        }
    }
}

extension ExerciseDetailViewModel {
    var score: String {
        let latestRatedResult = exercise.value?.baseExercise.latestRatedResult

        let resultScore = latestRatedResult?.score ?? 0
        let maxPoints = exercise.value?.baseExercise.maxPoints ?? 0
        let finalScore = round(resultScore * maxPoints / 10) / 10

        return finalScore.clean
    }

    var isFeedbackButtonVisible: Bool {
        switch exercise.value {
        case .fileUpload, .programming, .text:
            return true
        default:
            return false
        }
    }

    var isExerciseParticipationAvailable: Bool {
        // TODO: Re-enable when fixed
//        switch exercise.value {
//        case .modeling, .text:
//            return true
//        default:
//            return false
//        }
        false
    }
}

extension BaseExercise {
    var latestRatedResult: Result? {
        guard let participations = studentParticipations else { return nil }

        var allRatedResults: [Result] = []

        for participation in participations {
            let submissions = participation.baseParticipation.submissions ?? []
            for submission in submissions {
                let results = submission.baseSubmission.results ?? []
                let ratedResults = results.compactMap { $0 }.filter { $0.rated == true }
                allRatedResults.append(contentsOf: ratedResults)
            }
        }

        return allRatedResults.max(by: {
            ($0.completionDate ?? .distantPast) < ($1.completionDate ?? .distantPast)
        })
    }
}
