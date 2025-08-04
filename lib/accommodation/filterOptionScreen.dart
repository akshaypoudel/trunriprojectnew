import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trunriproject/accommodation/showFilterDataScreen.dart';

class FilterOptionScreen extends StatefulWidget {
  const FilterOptionScreen({super.key});

  @override
  State<FilterOptionScreen> createState() => _FilterOptionScreenState();
}

class _FilterOptionScreenState extends State<FilterOptionScreen> {
  List<String> propertyAmenities = [];
  List<String> homeRules = [];

  String? selectedCity;
  int singleBadRoom = 0;
  int doubleBadRoom = 0;
  int bathrooms = 0;
  int toilets = 0;
  int livingFemale = 0;
  int livingMale = 0;
  int livingNonBinary = 0;
  List<String> roomAmenities = [];
  RangeValues currentRangeValues = const RangeValues(10, 80);
  bool male = false;
  bool female = false;
  bool nonBinary = false;
  bool isstudents = false;
  bool isemployees = false;
  bool isfamilies = false;
  bool isSingleIndividuals = false;
  bool isCouples = false;

  bool showGenderError = false;
  bool showSituationError = false;

  bool isLiftAvailable = false;
  String bedroomFacing = '';
  bool isBedInRoom = false;
  bool showError = false;

  final List<String> stateList = [
    'Queensland',
    'Victoria',
    'NSW',
    'South Australia',
    'Western Australia',
    'Northern Territory',
    'Tasmania'
  ];

  final Map<String, List<String>> stateCityMap = {
    'Queensland': [
      'Brisbane',
      'Gold Coast',
      'Sunshine Coast',
      'Townsville',
      'Cairns',
      'Toowoomba',
      'Mackay',
      'Rockhampton',
      'Bundaberg',
      'Hervey Bay',
      'Gladstone',
      'Maryborough',
      'Mount Isa',
      'Gympie',
      'Warwick',
      'Emerald',
      'Dalby',
      'Bowen',
      'Charters Towers',
      'Kingaroy',
    ],
    'Victoria': [
      'Melbourne',
      'Geelong',
      'Ballarat',
      'Bendigo',
      'Shepparton',
      'Mildura',
      'Warrnambool',
      'Traralgon',
      'Wodonga',
      'Wangaratta',
      'Horsham',
      'Moe',
      'Morwell',
      'Sale',
      'Bairnsdale',
      'Benalla',
    ],
    'NSW': [
      'Sydney',
      'Newcastle',
      'Central Coast',
      'Wollongong',
      'Albury',
      'Armidale',
      'Bathurst',
      'Blue Mountains',
      'Broken Hill',
      'Campbelltown',
      'Cessnock',
      'Dubbo',
      'Goulburn',
      'Grafton',
      'Griffith',
      'Lake Macquarie',
      'Lismore',
      'Lithgow',
      'Maitland',
      'Nowra',
      'Orange',
      'Parramatta',
      'Penrith',
      'Port Macquarie',
      'Queanbeyan',
      'Richmond-Windsor',
      'Shellharbour',
      'Shoalhaven',
      'Tamworth',
      'Taree',
      'Tweed Heads',
      'Wagga Wagga',
      'Wyong',
      'Fairfield',
      'Hawkesbury',
      'Kiama',
      'Singleton',
      'Yass',
    ],
    'South Australia': [
      'Adelaide',
      'Mount Gambier',
      'Port Augusta',
      'Port Lincoln',
      'Port Pirie',
      'Whyalla',
    ],
    'Western Australia': [
      'Perth',
      'Albany',
      'Armadale',
      'Bunbury',
      'Busselton',
      'Fremantle',
      'Geraldton',
      'Kalgoorlie',
    ],
    'Northern Territory': [
      'Darwin',
      'Palmerston',
    ],
    'Tasmania': [
      'Hobart',
      'Launceston',
      'Devonport',
      'Burnie',
    ],
  };

  String? selectedState;
  List<String> cityList = [];
  bool isFormValid() {
    bool genderSelected = male || female || nonBinary;
    bool situationSelected = isstudents ||
        isemployees ||
        isfamilies ||
        isSingleIndividuals ||
        isCouples;
    return genderSelected && situationSelected;
  }

  void showToast(String message) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
            label: 'OK', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }

  void _updateCounter(String key, bool increment) {
    setState(() {
      switch (key) {
        case 'singleBadRoom':
          singleBadRoom = increment
              ? singleBadRoom + 1
              : (singleBadRoom > 0 ? singleBadRoom - 1 : 0);
          break;
        case 'doubleBadRoom':
          doubleBadRoom = increment
              ? doubleBadRoom + 1
              : (doubleBadRoom > 0 ? doubleBadRoom - 1 : 0);
          break;
        case 'bathrooms':
          bathrooms =
              increment ? bathrooms + 1 : (bathrooms > 0 ? bathrooms - 1 : 0);
          break;
        case 'toilets':
          toilets = increment ? toilets + 1 : (toilets > 0 ? toilets - 1 : 0);
          break;
        case 'livingFemale':
          livingFemale = increment
              ? livingFemale + 1
              : (livingFemale > 0 ? livingFemale - 1 : 0);
          break;
        case 'livingMale':
          livingMale = increment
              ? livingMale + 1
              : (livingMale > 0 ? livingMale - 1 : 0);
          break;
        case 'livingNonBinary':
          livingNonBinary = increment
              ? livingNonBinary + 1
              : (livingNonBinary > 0 ? livingNonBinary - 1 : 0);
          break;
      }
    });
  }

  Widget _buildCounterRow(String label, String key, int value) {
    return Row(
      children: [
        Text(label),
        const Spacer(),
        GestureDetector(
          onTap: () => _updateCounter(key, false),
          child: const CircleAvatar(
            maxRadius: 15,
            backgroundColor: Color(0xffFF730A),
            minRadius: 15,
            child: Icon(
              Icons.remove,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('$value'),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _updateCounter(key, true),
          child: const CircleAvatar(
            maxRadius: 15,
            minRadius: 15,
            backgroundColor: Color(0xffFF730A),
            child: Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  bool isFormComplete() {
    if (singleBadRoom == 0 &&
        doubleBadRoom == 0 &&
        bathrooms == 0 &&
        toilets == 0 &&
        livingFemale == 0 &&
        livingMale == 0 &&
        livingNonBinary == 0) {
      return false;
    }
    if (bedroomFacing.isEmpty) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: AppBar(
          title: const Text('Filter'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.only(left: 15, right: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'State',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Colors.black),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedState,
                    dropdownColor: Colors.white,
                    items: stateList.map((String state) {
                      return DropdownMenuItem<String>(
                        value: state,
                        child: Text(state),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedState = newValue;
                        cityList = stateCityMap[newValue] ?? [];
                        selectedCity = null; // Reset selected city
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Select state',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    validator: (value) {
                      if (value == null) {
                        return 'State is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  const Text(
                    'City',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Colors.black),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedCity,
                    dropdownColor: Colors.white,
                    items: cityList.map((String city) {
                      return DropdownMenuItem<String>(
                        value: city,
                        child: Text(city),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedCity = newValue;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Select City',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    validator: (value) {
                      if (value == null) {
                        return 'City is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const Text(
                    'What type of residence are you interested in?',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.black),
                  ),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('A room'),
                        selected: roomAmenities.contains('A room'),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              roomAmenities.add('A room');
                            } else {
                              roomAmenities.removeWhere((String name) {
                                return name == 'A room';
                              });
                            }
                          });
                        },
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      FilterChip(
                        label: const Text('Entire home for rent'),
                        selected:
                            roomAmenities.contains('Entire home for rent'),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              roomAmenities.add('Entire home for rent');
                            } else {
                              roomAmenities.removeWhere((String name) {
                                return name == 'Entire home for rent';
                              });
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('Studio unit'),
                        selected: roomAmenities.contains('Studio unit'),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              roomAmenities.add('Studio unit');
                            } else {
                              roomAmenities.removeWhere((String name) {
                                return name == 'Studio unit';
                              });
                            }
                          });
                        },
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      FilterChip(
                        label: const Text('Granny flat'),
                        selected: roomAmenities.contains('Granny flat'),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              roomAmenities.add('Granny flat');
                            } else {
                              roomAmenities.removeWhere((String name) {
                                return name == 'Granny flat';
                              });
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('Single bed unit'),
                        selected: roomAmenities.contains('Single bed unit'),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              roomAmenities.add('Single bed unit');
                            } else {
                              roomAmenities.removeWhere((String name) {
                                return name == 'Single bed unit';
                              });
                            }
                          });
                        },
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      FilterChip(
                        label: const Text('Shared bedroom'),
                        selected: roomAmenities.contains('Shared bedroom'),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              roomAmenities.add('Shared bedroom');
                            } else {
                              roomAmenities.removeWhere((String name) {
                                return name == 'Shared bedroom';
                              });
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      FilterChip(
                        label:
                            const Text('Shared room / rooms in shared house'),
                        selected: roomAmenities
                            .contains('Shared room / rooms in shared house'),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              roomAmenities
                                  .add('Shared room / rooms in shared house');
                            } else {
                              roomAmenities.removeWhere((String name) {
                                return name ==
                                    'Shared room / rooms in shared house';
                              });
                            }
                          });
                        },
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 30),
                      const Text(
                        'Is there a lift?',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Radio<bool>(
                            value: true,
                            activeColor: const Color(0xffFF730A),
                            groupValue: isLiftAvailable,
                            onChanged: (value) {
                              setState(() {
                                isLiftAvailable = value!;
                              });
                            },
                          ),
                          const Text('Yes'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Radio<bool>(
                            value: false,
                            activeColor: const Color(0xffFF730A),
                            groupValue: isLiftAvailable,
                            onChanged: (value) {
                              setState(() {
                                isLiftAvailable = value!;
                              });
                            },
                          ),
                          const Text('No'),
                        ],
                      ),
                      if (showError && !isLiftAvailable)
                        const Text(
                          'Please specify if there is a lift',
                          style: TextStyle(color: Colors.red),
                        ),
                      const SizedBox(height: 10),
                      const Text(
                        'How many bedrooms?',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      _buildCounterRow(
                          'Single Bedrooms', 'singleBadRoom', singleBadRoom),
                      const SizedBox(height: 5),
                      Divider(thickness: 1, color: Colors.grey.shade300),
                      const SizedBox(height: 5),
                      _buildCounterRow(
                          'Double Bedrooms', 'doubleBadRoom', doubleBadRoom),
                      if (showError && singleBadRoom == 0 && doubleBadRoom == 0)
                        const Text(
                          'Please add at least one bedroom',
                          style: TextStyle(color: Colors.red),
                        ),
                      const SizedBox(height: 20),
                      const Text(
                        'How many bathrooms?',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      _buildCounterRow('Bathrooms', 'bathrooms', bathrooms),
                      const SizedBox(height: 5),
                      Divider(thickness: 1, color: Colors.grey.shade300),
                      const SizedBox(height: 5),
                      _buildCounterRow('Toilets', 'toilets', toilets),
                      if (showError && bathrooms == 0 && toilets == 0)
                        const Text(
                          'Please add at least one bathroom or toilet',
                          style: TextStyle(color: Colors.red),
                        ),
                      const SizedBox(height: 20),
                      const Text(
                        'Who is currently living in the property?',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      _buildCounterRow('Females', 'livingFemale', livingFemale),
                      const SizedBox(height: 5),
                      Divider(thickness: 1, color: Colors.grey.shade300),
                      const SizedBox(height: 5),
                      _buildCounterRow('Males', 'livingMale', livingMale),
                      const SizedBox(height: 5),
                      Divider(thickness: 1, color: Colors.grey.shade300),
                      const SizedBox(height: 5),
                      _buildCounterRow(
                          'Non-Binary', 'livingNonBinary', livingNonBinary),
                      if (showError &&
                          livingFemale == 0 &&
                          livingMale == 0 &&
                          livingNonBinary == 0)
                        const Text(
                          'Please add at least one person',
                          style: TextStyle(color: Colors.red),
                        ),
                      const SizedBox(height: 20),
                      const Text(
                        'Room Amenities',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black),
                      ),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('Wardrobe'),
                            selected: roomAmenities.contains('Wardrobe'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  roomAmenities.add('Wardrobe');
                                } else {
                                  roomAmenities.removeWhere((String name) {
                                    return name == 'Wardrobe';
                                  });
                                }
                              });
                            },
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          FilterChip(
                            label: const Text('Air conditioning'),
                            selected:
                                roomAmenities.contains('Air conditioning'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  roomAmenities.add('Air conditioning');
                                } else {
                                  roomAmenities.removeWhere((String name) {
                                    return name == 'Air conditioning';
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('heating controls'),
                            selected:
                                roomAmenities.contains('heating controls'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  roomAmenities.add('heating controls');
                                } else {
                                  roomAmenities.removeWhere((String name) {
                                    return name == 'heating controls';
                                  });
                                }
                              });
                            },
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          FilterChip(
                            label: const Text('WI-FI'),
                            selected: roomAmenities.contains('WI-FI'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  roomAmenities.add('WI-FI');
                                } else {
                                  roomAmenities.removeWhere((String name) {
                                    return name == 'WI-FI';
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('curtains'),
                            selected: roomAmenities.contains('curtains'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  roomAmenities.add('curtains');
                                } else {
                                  roomAmenities.removeWhere((String name) {
                                    return name == 'curtains';
                                  });
                                }
                              });
                            },
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          FilterChip(
                            label: const Text('shelves'),
                            selected: roomAmenities.contains('shelves'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  roomAmenities.add('shelves');
                                } else {
                                  roomAmenities.removeWhere((String name) {
                                    return name == 'shelves';
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Property Amenities',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('Gym'),
                            selected: propertyAmenities.contains('Gym'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  propertyAmenities.add('Gym');
                                } else {
                                  propertyAmenities.removeWhere((String name) {
                                    return name == 'Gym';
                                  });
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 5),
                          FilterChip(
                            label: const Text('Garden'),
                            selected: propertyAmenities.contains('Garden'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  propertyAmenities.add('Garden');
                                } else {
                                  propertyAmenities.removeWhere((String name) {
                                    return name == 'Garden';
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('Laundry facilities'),
                            selected: propertyAmenities
                                .contains('Laundry facilities'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  propertyAmenities.add('Laundry facilities');
                                } else {
                                  propertyAmenities.removeWhere((String name) {
                                    return name == 'Laundry facilities';
                                  });
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 5),
                          FilterChip(
                            label: const Text('Swimming pool'),
                            selected:
                                propertyAmenities.contains('Swimming pool'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  propertyAmenities.add('Swimming pool');
                                } else {
                                  propertyAmenities.removeWhere((String name) {
                                    return name == 'Swimming pool';
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('garage'),
                            selected: propertyAmenities.contains('garage'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  propertyAmenities.add('garage');
                                } else {
                                  propertyAmenities.removeWhere((String name) {
                                    return name == 'garage';
                                  });
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 5),
                          FilterChip(
                            label: const Text('parking space'),
                            selected:
                                propertyAmenities.contains('parking space'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  propertyAmenities.add('parking space');
                                } else {
                                  propertyAmenities.removeWhere((String name) {
                                    return name == 'parking space';
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('television'),
                            selected: propertyAmenities.contains('television'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  propertyAmenities.add('television');
                                } else {
                                  propertyAmenities.removeWhere((String name) {
                                    return name == 'television';
                                  });
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 5),
                          FilterChip(
                            label: const Text('iron'),
                            selected: propertyAmenities.contains('iron'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  propertyAmenities.add('iron');
                                } else {
                                  propertyAmenities.removeWhere((String name) {
                                    return name == 'iron';
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('refrigerator'),
                            selected:
                                propertyAmenities.contains('refrigerator'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  propertyAmenities.add('refrigerator');
                                } else {
                                  propertyAmenities.removeWhere((String name) {
                                    return name == 'refrigerator';
                                  });
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 5),
                          FilterChip(
                            label: const Text('microwave'),
                            selected: propertyAmenities.contains('microwave'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  propertyAmenities.add('microwave');
                                } else {
                                  propertyAmenities.removeWhere((String name) {
                                    return name == 'microwave';
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('dishwasher'),
                            selected: propertyAmenities.contains('dishwasher'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  propertyAmenities.add('dishwasher');
                                } else {
                                  propertyAmenities.removeWhere((String name) {
                                    return name == 'dishwasher';
                                  });
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 5),
                          FilterChip(
                            label: const Text('bath tub'),
                            selected: propertyAmenities.contains('bath tub'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  propertyAmenities.add('bath tub');
                                } else {
                                  propertyAmenities.removeWhere((String name) {
                                    return name == 'bath tub';
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('grill'),
                            selected: propertyAmenities.contains('grill'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  propertyAmenities.add('grill');
                                } else {
                                  propertyAmenities.removeWhere((String name) {
                                    return name == 'grill';
                                  });
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 5),
                          FilterChip(
                            label: const Text('fire pit'),
                            selected: propertyAmenities.contains('fire pit'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  propertyAmenities.add('fire pit');
                                } else {
                                  propertyAmenities.removeWhere((String name) {
                                    return name == 'fire pit';
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('smoke Alarams'),
                            selected:
                                propertyAmenities.contains('smoke Alarams'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  propertyAmenities.add('smoke Alarams');
                                } else {
                                  propertyAmenities.removeWhere((String name) {
                                    return name == 'smoke Alarams';
                                  });
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 5),
                          FilterChip(
                            label: const Text('security system'),
                            selected:
                                propertyAmenities.contains('security system'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  propertyAmenities.add('security system');
                                } else {
                                  propertyAmenities.removeWhere((String name) {
                                    return name == 'security system';
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('balcony'),
                            selected: propertyAmenities.contains('balcony'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  propertyAmenities.add('balcony');
                                } else {
                                  propertyAmenities.removeWhere((String name) {
                                    return name == 'balcony';
                                  });
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 5),
                          FilterChip(
                            label: const Text('deck'),
                            selected: propertyAmenities.contains('deck'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  propertyAmenities.add('deck');
                                } else {
                                  propertyAmenities.removeWhere((String name) {
                                    return name == 'deck';
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('sound system'),
                            selected:
                                propertyAmenities.contains('sound system'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  propertyAmenities.add('sound system');
                                } else {
                                  propertyAmenities.removeWhere((String name) {
                                    return name == 'sound system';
                                  });
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 5),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Home Rules',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('no drinking'),
                            selected: homeRules.contains('no drinking'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  homeRules.add('no drinking');
                                } else {
                                  homeRules.removeWhere((String name) {
                                    return name == 'no drinking';
                                  });
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 5),
                          FilterChip(
                            label: const Text('No smoking'),
                            selected: homeRules.contains('No smoking'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  homeRules.add('No smoking');
                                } else {
                                  homeRules.removeWhere((String name) {
                                    return name == 'No smoking';
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('Night out'),
                            selected: homeRules.contains('Night out'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  homeRules.add('Night out');
                                } else {
                                  homeRules.removeWhere((String name) {
                                    return name == 'Night out';
                                  });
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 5),
                          FilterChip(
                            label: const Text('no pets'),
                            selected: homeRules.contains('no pets'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  homeRules.add('no pets');
                                } else {
                                  homeRules.removeWhere((String name) {
                                    return name == 'no pets';
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('no guests'),
                            selected: homeRules.contains('no guests'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  homeRules.add('no guests');
                                } else {
                                  homeRules.removeWhere((String name) {
                                    return name == 'no guests';
                                  });
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 5),
                          FilterChip(
                            label: const Text('no parties'),
                            selected: homeRules.contains('no parties'),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  homeRules.add('no parties');
                                } else {
                                  homeRules.removeWhere((String name) {
                                    return name == 'no parties';
                                  });
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Price Range',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black),
                      ),
                      RangeSlider(
                        values: currentRangeValues,
                        min: 0,
                        max: 750,
                        divisions: 20,
                        activeColor: const Color(0xffFF730A),
                        labels: RangeLabels(
                          '\$${currentRangeValues.start.round()}',
                          '\$${currentRangeValues.end.round()}',
                        ),
                        onChanged: (RangeValues values) {
                          setState(() {
                            currentRangeValues = values;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Preferred Gender',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        title: const Text('Male'),
                        value: male,
                        activeColor: const Color(0xffFF730A),
                        onChanged: (value) {
                          setState(() {
                            male = value!;
                            showGenderError = false;
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Female'),
                        value: female,
                        activeColor: const Color(0xffFF730A),
                        onChanged: (value) {
                          setState(() {
                            female = value!;
                            showGenderError = false;
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Non-Binary'),
                        value: nonBinary,
                        activeColor: const Color(0xffFF730A),
                        onChanged: (value) {
                          setState(() {
                            nonBinary = value!;
                            showGenderError = false;
                          });
                        },
                      ),
                      if (showGenderError)
                        const Text(
                          'Please select at least one gender',
                          style: TextStyle(color: Colors.red),
                        ),
                      const SizedBox(height: 20),
                      const Text(
                        'Living Situation',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        title: const Text('students'),
                        value: isstudents,
                        activeColor: const Color(0xffFF730A),
                        onChanged: (value) {
                          setState(() {
                            isstudents = value!;
                            showSituationError = false;
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('employees'),
                        value: isemployees,
                        activeColor: const Color(0xffFF730A),
                        onChanged: (value) {
                          setState(() {
                            isemployees = value!;
                            showSituationError = false;
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('families'),
                        value: isfamilies,
                        activeColor: const Color(0xffFF730A),
                        onChanged: (value) {
                          setState(() {
                            isfamilies = value!;
                            showSituationError = false;
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('single individuals'),
                        value: isSingleIndividuals,
                        activeColor: const Color(0xffFF730A),
                        onChanged: (value) {
                          setState(() {
                            isSingleIndividuals = value!;
                            showSituationError = false;
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('couples'),
                        value: isCouples,
                        activeColor: const Color(0xffFF730A),
                        onChanged: (value) {
                          setState(() {
                            isCouples = value!;
                            showSituationError = false;
                          });
                        },
                      ),
                      if (showSituationError)
                        const Text(
                          'Please select at least one living situation',
                          style: TextStyle(color: Colors.red),
                        ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          Get.to(() => ShowFilterDataScreen(
                                propertyAmenities: propertyAmenities,
                                homeRules: homeRules,
                                bathrooms: bathrooms,
                                bedroomFacing: bedroomFacing,
                                // currentRangeValues: currentRangeValues,
                                // doubleBadRoom: doubleBadRoom,
                                // female: female,
                                // isBedInRoom: isBedInRoom,
                                // isDontMind: isDontMind,
                                // isLiftAvailable: isLiftAvailable,
                                // isStudying: isStudying,
                                // isWorking: isWorking,
                                // livingFemale: livingFemale,
                                // livingMale: livingMale,
                                // livingNonBinary: livingNonBinary,
                                // male: male,
                                // nonBinary: nonBinary,
                                // roomAmenities: roomAmenities,
                                selectedCity: selectedCity,
                                // showGenderError: showGenderError,
                                // showError: showError,
                                // showSituationError: showSituationError,
                                // singleBadRoom: singleBadRoom,
                                // toilets: toilets,
                              ));
                        },
                        child: Container(
                          width: size.width,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xffFF730A),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Center(
                            child: Text(
                              "Click Here To Filter",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
