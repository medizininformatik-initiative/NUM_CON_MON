#!/usr/bin/env bb

(require '[babashka.fs :as fs]
         '[clojure.java.shell :refer [sh]]
         '[cheshire.core :as json])

(import '[java.time LocalDate OffsetDateTime ZoneOffset])
(import '[java.time.format DateTimeFormatter])

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
      :_value
      {:extension
       [{:url "http://hl7.org/fhir/StructureDefinition/data-absent-reason"
         :valueCode "masked"}]}
      :assigner
      {:identifier
       {:type
        {:coding
         [{:system "http://terminology.hl7.org/CodeSystem/v2-0203"
           :code "XX"}]}
        :system "http://fhir.de/sid/arge-ik/iknr"
        :value ik-number}}}]}
    (#{"male" "female"} gender) (assoc :gender gender)
    (#{"D" "X"} gender)
    (assoc :gender "other"
           :_gender {:extension
                     [{:url "http://fhir.de/StructureDefinition/gender-amtlich-de"
                       :valueCoding
                       {:system "http://fhir.de/CodeSystem/gender-amtlich-de"
                        :code gender}}]})
    birthDate (assoc :birthDate birthDate)))

(defn consent-resource [{:keys [id patient-id date code]}]
  {:resourceType "Consent"
   :id id
   :patient {:reference (str "Patient/" patient-id)}
   :dateTime (.format DateTimeFormatter/ISO_OFFSET_DATE_TIME date)
   :provision
   {:provision
    [{:type "permit"
      :period
      {:start (.format DateTimeFormatter/ISO_OFFSET_DATE_TIME date)
       :end (.format DateTimeFormatter/ISO_OFFSET_DATE_TIME (.plusYears date 5))}
      :code
      [{:coding
        [{:system "urn:oid:2.16.840.1.113883.3.1937.777.24.5.3"
          :code code}]}
       {:coding
        [{:system "foo"
          :code "bar"}]}]}]}})

(defn encounter-resource
  [{:keys [id status type department-key patient-id start-date-time end-date-time]}]
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
     [department-key]}
    :subject {:reference (str "Patient/" patient-id)}}
    start-date-time (assoc-in [:period :start] (.format DateTimeFormatter/ISO_LOCAL_DATE start-date-time))
    end-date-time (assoc-in [:period :end] (.format DateTimeFormatter/ISO_LOCAL_DATE end-date-time))))

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
   (for [ik-number (take 20 ik-numbers)
         gender [nil "male" "female" "male" "female" "male" "female" "male" "female" "D" "X"]
         birthDate (cons nil (range 1950 2020))]
     {:ik-number ik-number
      :gender gender
      :birthDate (some-> birthDate str)})))

(defn rand-date []
  (LocalDate/of ^int (- 2025 (rand-int 100)) ^int (inc (rand-int 12)) ^int (inc (rand-int 28))))

(defn rand-date-time []
  (OffsetDateTime/of ^int (- 2025 (rand-int 100)) ^int (inc (rand-int 12)) ^int (inc (rand-int 28))
                     ^int (rand-int 23) ^int (rand-int 60) ^int (rand-int 60) 0 ZoneOffset/UTC))

(defn gen-consent-data [patient-id]
  {:id patient-id
   :patient-id patient-id
   :date (rand-date-time)
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

(def extended-department-keys
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
   "3700"
   "0102"
   "0103"
   "0104"
   "0105"
   "0106"
   "0107"
   "0108"
   "0109"
   "0114"
   "0150"
   "0151"
   "0152"
   "0153"
   "0154"
   "0156"
   "0224"
   "0260"
   "0261"
   "0410"
   "0436"
   "0510"
   "0524"
   "0533"
   "0607"
   "0610"
   "0706"
   "0710"
   "0910"
   "1004"
   "1005"
   "1006"
   "1007"
   "1009"
   "1011"
   "1012"
   "1014"
   "1028"
   "1050"
   "1051"
   "1136"
   "1410"
   "1513"
   "1516"
   "1518"
   "1519"
   "1520"
   "1523"
   "1536"
   "1550"
   "1551"
   "2021"
   "2036"
   "2050"
   "2118"
   "2120"
   "2136"
   "2150"
   "2309"
   "2315"
   "2402"
   "2405"
   "2406"
   "2810"
   "2851"
   "2852"
   "2856"
   "2928"
   "2930"
   "2931"
   "2950"
   "2951"
   "2952"
   "2953"
   "2954"
   "2955"
   "2956"
   "2960"
   "2961"
   "3060"
   "3061"
   "3110"
   "3160"
   "3161"
   "3233"
   "3305"
   "3350"
   "3460"
   "3601"
   "3603"
   "3610"
   "3617"
   "3618"
   "3621"
   "3622"
   "3624"
   "3626"
   "3628"
   "3650"
   "3651"
   "3652"
   "3750"
   "3751"
   "3752"
   "3753"
   "3754"
   "3755"
   "3756"
   "3757"
   "3758"])

(defn rand-department-key []
  {:system "http://fhir.de/CodeSystem/dkgev/Fachabteilungsschluessel"
   :code (rand-nth department-keys)})

(defn rand-extended-department-key []
  {:system "http://fhir.de/CodeSystem/dkgev/Fachabteilungsschluessel-erweitert"
   :code (rand-nth extended-department-keys)})

(defn gen-encounter-data [patient-id]
  (map-indexed
   #(assoc %2 :id (str patient-id "-" %1))
   (for [status (repeatedly 4 #(rand-nth ["planned" "in-progress" "onleave" "finished" "finished" "finished" "cancelled" "entered-in-error" "unknown"]))
         type (repeatedly 2 #(rand-nth ["einrichtungskontakt" "abteilungskontakt" "versorgungsstellenkontakt"]))
         department-key [(rand-department-key) (rand-extended-department-key)]
         start-date-time (repeatedly 2 #(rand-date-time))]
     (cond->
      {:status status
       :type type
       :department-key department-key
       :patient-id patient-id}
       ;; 10 % non existing start date
       (and (#{"in-progress" "finished"} status) (< (rand) 0.9))
       (assoc :start-date-time start-date-time)
       ;; 10 % non existing end date
       (and (#{"finished"} status) (< (rand) 0.9))
       ;; some end dates are before the start date
       (assoc :end-date-time (.plusMonths start-date-time (dec (rand-int 14))))))))

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
