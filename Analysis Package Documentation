### Analysis Package Elements
This document lists and describes the elements required for an analysis package. Here, an element is defined as categorical information needed to understand and use the package in a traceable and repeatable manner. Each element needs to be explicitly present in the package's code and supporting documents. All the elements listed below are required for analysis package review, acceptance and deployment.

#### Purpose
Describe the purpose of the analysis package. What does it do? What does the user come away with? Having a clear and concise description is critical to develop, assess, validate and review the analyses and visualizations with colleagues and developers. Plus, it will be critical for the formal review process of your work

As an example, look at "Protection Status of Ecological Systems by Ecoregion", the first BAP listed at <https://maps.usgs.gov/biogeography>, clicking on the BAP's information "i" pulls this and other pertinent text from ScienceBase:
> This provisional Biogeographic Analysis Package provides an analysis of protection status for ecological systems within Omernik Level III Ecoregions.  The ecological system classification defines groups of plant communities that tend to co-occur within landscapes with similar ecological processes, substrates, and/or environmental gradients and is the primary map class used in the Gap Analysis Program (GAP) land cover layer (based on 2001 satellite imagery).  This package can be used to identify the ecoregions where ecological systems have the greatest representation in GAP Status 1 and 2 lands (lands managed for the protection of biodiversity) and the ecoregions where ecological systems are the least protected.

> One important use of the data in this Biogeographic Analysis Package is to evaluate what proportion of the ecological systems in an ecoregion are managed for long-term conservation. These data can be expressed as “threshold” levels of ecological system protection. These thresholds provide a convenient reporting framework ... (<https://www.sciencebase.gov/catalog/item/5645fa07e4b0e2669b30f267>, retrieved 2018-02-20)

#### Inputs
Document all inputs. Names, links, security constraints, spatial extent and resolution, temporal extent and resolution, example code to access are all important to capture. Documenting these early on makes it easier for others to jump in and help debug, capture the provenance and, later in the process, are critical to the developers operationalizing the scientific code.

#### Outputs
Document all outputs. Again names, links, security constraints, spatial extent and resolution, temporal extent and resolution, example output code all help speed development and ensure repeatability. We'll also need this for the review(s).

#### Constraints
List and adequately explain any analytical constraints. For example, is the analysis only appropriate at a certain scale? Are there temporal aspects that must be met for a valid analysis? What conditions need to be met before performing a given analysis?

#### Dependencies
List all dependencies. Are there specific software libraries, packages, or other BAPs that are required to do this analysis? If so, what are they called, where can they be found and what version did you use? All this will also be wrapped up in the provenance trace.

#### Code
Where is your code? It needs to be under source control in a publically accessible repository. Most of us use GitHub for our development but that choice is yours. Note the official USGS repos are required for disseminating final, authorized for release code. What is your code written in? R? Python? We use both for the science code and a mix for operational. Note, for sanity we always try to code against APIs and standards (e.g. W3C and OGC). It is a simple best practice. Plus, we tend to capture much of this in Jupyter notebooks under source control that we can share and collaborate on.

#### Tests
Tests for BAPs are both conceptual and technical. A core principle we are pursuing in the BAP quest is the idea of a logical test for the applicability of what the BAP does with an appropriate stakeholder. At this stage of our development, we need to make sure that the BAPs we are spending time on can be directly applied to resource management or policymaking decision analysis. A key element of documenting a BAP is figuring out what this use may be and designing an engagement plan for testing and incorporating results into future work.

Also consider baking technical tests into the code part of a BAP. This is really important when we toss things to the developers. We are the domain experts. And since we have captured the previous five things, we need to communicate what the answers are to the folks that grab our science code and make it live. While they have broad and diverse experience working in this area, they may not know what the "right" answer looks like. We need to give them examples to work with and build from.

#### Provenance
Provenance is required. This is built into the system. Several of the previous items feed into that integral subsystem, so this will not be a difficult requirement to meet. We follow W3C PROV closely.

#### Citations
We need them. Just as for your papers, citations provide the scholarly basis for your choice of methodology and implementation, and, given the reusable requirement, provide the background users need to understand and use your BAP for their own work.

All of this information will be made available for the review processes. There are at least three of them. Two of these, the daily ongoing and the internal, are informal and involve working with your branch and program colleagues. The two BAPs we talked about, the ones at <https://maps.usgs.gov/biogeography>, have gone through both of these informal reviews. The other BAPs currently in development are queueing up for the internal. Every BAP will go through the appropriate level of formal review before it is authorized for official release.
