def data_absent_reason(node): node.extension[] | select(.url == "http://hl7.org/fhir/StructureDefinition/data-absent-reason").valueCode;
def count(population): if population._count then data_absent_reason(population._count) else population.count end;
