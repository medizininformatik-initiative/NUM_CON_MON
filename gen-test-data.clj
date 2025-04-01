#!/usr/bin/env bb

(require '[babashka.fs :as fs]
         '[clojure.java.shell :refer [sh]]
         '[cheshire.core :as json])

(defn patient-resource [{:keys [id ik-number gender birthDate]}]
  (cond->
   {:resourceType "Patient"
    :id id
    :identifier
    [{:type
      {:coding
       [{:system "http://fhir.de/CodeSystem/identifier-type-de-basis"
         :code (rand-nth (into ["GKV"] (repeat 9 "KVZ10")))}]}
      :system "http://fhir.de/sid/gkv/kvid-10"
      :value "123456"
      :assigner
      {:identifier
       {:type
        {:coding
         [{:system "http://terminology.hl7.org/CodeSystem/v2-0203"
           :code "XX"}]}
        :system "http://fhir.de/sid/arge-ik/iknr"
        :value ik-number}}}]}
    gender (assoc :gender gender)
    birthDate (assoc :birthDate birthDate)))

(defn consent-resource [{:keys [id patient-id code]}]
  {:resourceType "Consent"
   :id id
   :patient {:reference (str "Patient/" patient-id)}
   :provision
   {:provision
    [{:code
      [{:coding
        [{:system "urn:oid:2.16.840.1.113883.3.1937.777.24.5.3"
          :code code}]}]}]}})

(defn encounter-resource
  [{:keys [id status type department-key patient-id start-date-time]}]
  (cond->
   {:resourceType "Encounter"
    :id id
    :status status
    :type
    [{:coding
      [{:system "http://fhir.de/CodeSystem/Kontaktebene"
        :code type}]}]
    :serviceType
    {:coding
     [{:system "http://fhir.de/CodeSystem/dkgev/Fachabteilungsschluessel"
       :code department-key}]}
    :subject {:reference (str "Patient/" patient-id)}}
    start-date-time (assoc :period {:start start-date-time})))

(defn patient-bundle
  [{{patient-id :id :as patient} :patient :keys [consent encounter]}]
  {:resourceType "Bundle"
   :type "transaction"
   :entry
   (into
    [{:resource (patient-resource patient)
      :request {:method "PUT" :url (str "Patient/" patient-id)}}
     (let [{:keys [id] :as consent} consent]
       {:resource (consent-resource consent)
        :request {:method "PUT" :url (str "Consent/" id)}})]
    (map
     (fn [{:keys [id] :as encounter}]
       {:resource (encounter-resource encounter)
        :request {:method "PUT" :url (str "Encounter/" id)}}))
    encounter)})

(def ik-numbers
  ["104127692"
   "108018121"
   "108310400"
   "103119199"
   "102114819"
   "105313145"
   "100395611"
   "100696012"
   "109519005"
   "101317004"
   "103411401"
   "105998018"
   "107299005"
   "101519213"
   "104212505"
   "106215364"
   "109319309"
   "101097008"
   "103121013"
   "108534160"
   "109938503"
   "100180008"
   "100580002"
   "100980006"
   "101380002"
   "101580004"
   "101780006"
   "103080003"
   "103480007"
   "104080005"
   "105080008"
   "105180009"
   "106280002"
   "106780007"
   "107280004"
   "108380007"
   "109380009"
   "109580001"
   "103725342"
   "103501080"
   "102122660"
   "103525909"
   "106229304"
   "107536171"
   "108833355"
   "108591499"
   "104626889"
   "105530422"
   "101532301"
   "103524101"
   "104626903"
   "105330157"
   "104424794"
   "106431572"
   "107835333"
   "103525567"
   "105928809"
   "104224634"
   "103724294"
   "103724249"
   "109139915"
   "104125509"
   "102429648"
   "102122557"
   "109033393"
   "103121137"
   "107036370"
   "103724272"
   "104424830"
   "107835071"
   "107835743"
   "104124597"
   "105530364"
   "103725547"
   "105530331"
   "105830539"
   "105330431"
   "108633433"])

(defn gen-patient-data []
  (map-indexed
   #(assoc %2 :id (str %1))
   (for [ik-number (take 10 ik-numbers)
         gender [nil "male" "female"]
         birthDate (cons nil (range 1950 2020))]
     {:ik-number ik-number
      :gender gender
      :birthDate (some-> birthDate str)})))

(defn gen-consent-data [patient-id]
  {:id patient-id
   :patient-id patient-id
   :code (rand-nth ["2.16.840.1.113883.3.1937.777.24.5.3.8"
                    "2.16.840.1.113883.3.1937.777.24.5.3.13"])})

(def department-keys
  ["0100"
   "0200"
   "0300"
   "0400"
   "0500"
   "0600"
   "0700"
   "0800"
   "0900"
   "1000"
   "1100"
   "1200"
   "1300"
   "1400"
   "1500"
   "1600"
   "1700"
   "1800"
   "1900"
   "2000"
   "2100"
   "2200"
   "2300"
   "2400"
   "2500"
   "2600"
   "2700"
   "2800"
   "2900"
   "3000"
   "3100"
   "3200"
   "3300"
   "3400"
   "3500"
   "3600"
   "2316"
   "2425"
   "3700"])

(defn rand-date-time []
  (format "%s-%02d-%02d" (- 2025 (rand-int 100)) (inc (rand-int 12)) (inc (rand-int 28))))

(defn gen-encounter-data [patient-id]
  (map-indexed
   #(assoc %2 :id (str patient-id "-" %1))
   (for [status (repeatedly 2 #(rand-nth ["planned" "in-progress" "onleave" "finished" "cancelled" "entered-in-error" "unknown"]))
         type (repeatedly 2 #(rand-nth ["einrichtungskontakt" "abteilungskontakt" "versorgungsstellenkontakt"]))
         department-key (repeatedly 2 #(rand-nth department-keys))
         start-date-time (repeatedly 2 #(rand-date-time))]
     (cond->
      {:status status
       :type type
       :department-key department-key
       :patient-id patient-id}
       (#{"in-progress" "finished"} status)
       (assoc :start-date-time start-date-time)))))

(defn gen-data []
  (for [{patient-id :id :as patient} (gen-patient-data)]
    {:patient patient
     :consent (gen-consent-data patient-id)
     :encounter (gen-encounter-data patient-id)}))

(comment
  (gen-patient-data)
  (gen-data)
  )

(fs/create-dirs "test-data")

(doseq [{{:keys [id]} :patient :as data} (gen-data)]
  (spit (str "test-data/patient-" id ".json") (json/generate-string (patient-bundle data))))
