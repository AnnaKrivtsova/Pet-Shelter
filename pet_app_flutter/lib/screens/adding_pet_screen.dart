import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_app/constants/constants.dart';
import 'package:pet_app/screens/splash_screen.dart';
import 'package:pet_app/utils/services/database.dart';

enum Gender { male, female }

enum PetStatus { lost, adopt }

class AddingPet extends StatefulWidget {
  const AddingPet({Key key}) : super(key: key);

  @override
  State<AddingPet> createState() => _AddingPetState();
}

class _AddingPetState extends State<AddingPet> {
  File imageFile;
  final picker = ImagePicker();
  Gender _selectedGender = Gender.male;
  PetStatus _petStatus = PetStatus.adopt;
  String category;
  String pickedGender = 'самец';
  String _pickedPetSatus = 'бездомный';
  TextEditingController _nameController;
  TextEditingController _speciesController;
  TextEditingController _ageController;
  TextEditingController _cityController;
  TextEditingController _streetController;
  TextEditingController _houseController;
  TextEditingController _descriptionController;
  DatabaseMethods databaseMethods = DatabaseMethods();

  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void initState() {
    _nameController = TextEditingController(text: "");
    _speciesController = TextEditingController(text: "");
    _ageController = TextEditingController(text: "");
    _cityController = TextEditingController(text: "");
    _streetController = TextEditingController(text: "");
    _houseController = TextEditingController(text: "");
    _descriptionController = TextEditingController(text: "");
    super.initState();
  }

  Future pickImage(ImageSource source) async {
    final temp = await picker.pickImage(
      source: source,
      maxHeight: 480,
      maxWidth: 640,
      imageQuality: 30,
    );
    if (temp != null) {
      setState(() {
        imageFile = File(temp.path);
      });
    }
    Navigator.pop(context);
  }

  uploadImage() async {
    final firebaseStorageRef = FirebaseStorage.instance
        .ref()
        .child(Constants.currentUser + DateTime.now().toString());
    final task = await firebaseStorageRef.putFile(imageFile);
    return task.ref.getDownloadURL();
  }

  void uploadPetAd() async {
    if (formKey.currentState.validate()) {
      setState(() {
        isLoading = true;
      });
      String url = await uploadImage();
      final DateTime dateToday = new DateTime.now();
      final String date = dateToday.toString().substring(0, 10);
      Map<String, dynamic> petInfoMap = {
        'name': _nameController.text,
        'species': _speciesController.text,
        'age': double.parse(_ageController.text),
        'imgUrl': url,
        'category': category,
        'sex': pickedGender,
        'petStatus': _pickedPetSatus,
        'owner': Constants.currentUser,
        'location':
            '${_cityController.text}, ${_streetController.text} ${_houseController.text}',
        'status': 'активно',
        'date': date,
        'description': _descriptionController.text,
      };
      databaseMethods.uploadPetInfo(petInfoMap);
    } else {
      setState(() {
        isLoading = false;
      });
      SnackBar snackBar = SnackBar(
        content: Text(
          'Некорректные поля!',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void clearControllers() {
    _ageController.clear();
    _cityController.clear();
    _descriptionController.clear();
    _nameController.clear();
    _houseController.clear();
    _speciesController.clear();
    _streetController.clear();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              padding: EdgeInsets.symmetric(
                vertical: screenSize.height * 0.05,
                horizontal: 15,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  width: 4,
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    spreadRadius: 2,
                                    blurRadius: 10,
                                    color: Colors.black.withOpacity(0.1),
                                    offset: Offset(0, 10),
                                  )
                                ],
                                shape: BoxShape.rectangle,
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: imageFile == null
                                      ? AssetImage("images/cat.png")
                                      : FileImage(imageFile),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    width: 4,
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                  ),
                                  color: Constants.kPrimaryColor,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (builder) =>
                                          bottomSheet(screenSize),
                                    );
                                  },
                                  child: Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Название питомца:",
                              style: TextStyle(
                                color: Constants.kPrimaryColor,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          InputWithIcon(
                            controller: _nameController,
                            icon: Icons.edit,
                            hint: "Название",
                            validator: (String value) {
                              return value.length > 20 ||
                                      value.length < 2 ||
                                      !RegExp(r'^[а-яА-Я][а-яА-Я ]*$')
                                          .hasMatch(value)
                                  ? 'Введите корректное название'
                                  : null;
                            },
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Порода питомца:",
                              style: TextStyle(
                                color: Constants.kPrimaryColor,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          InputWithIcon(
                            controller: _speciesController,
                            icon: Icons.edit,
                            hint: "Порода",
                            validator: (value) {
                              return value.length > 30 ||
                                      value.length < 2 ||
                                      !RegExp(r'^[а-яА-Я][а-яА-Я ]*$')
                                          .hasMatch(value)
                                  ? 'Введите корректное название'
                                  : null;
                            },
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Возраст питомца:",
                              style: TextStyle(
                                color: Constants.kPrimaryColor,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          InputWithIcon(
                            controller: _ageController,
                            icon: Icons.edit,
                            hint: "Возраст",
                            validator: (value) {
                              return value.length > 20 ||
                                      value.length < 2 ||
                                      value == null
                                  ? 'Введите корректное название'
                                  : null;
                            },
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Пол питомца:",
                              style: TextStyle(
                                color: Constants.kPrimaryColor,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: [
                              sexWidget("Самец", Gender.male),
                              SizedBox(
                                width: 20,
                              ),
                              sexWidget("Cамка", Gender.female)
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Категория питомца:",
                              style: TextStyle(
                                color: Constants.kPrimaryColor,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          categoryWidget(),
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Город:",
                              style: TextStyle(
                                color: Constants.kPrimaryColor,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          InputWithIcon(
                            controller: _cityController,
                            icon: Icons.edit,
                            hint: "Город",
                            validator: (value) {
                              return value.length > 20 ||
                                      value.length < 2 ||
                                      !RegExp(r'^[а-яА-Я]*$').hasMatch(value)
                                  ? 'Введите корректное название'
                                  : null;
                            },
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Улица:",
                              style: TextStyle(
                                color: Constants.kPrimaryColor,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          InputWithIcon(
                            controller: _streetController,
                            icon: Icons.edit,
                            hint: "Улица",
                            validator: (value) {
                              return value.length > 20 ||
                                      value.length < 2 ||
                                      !RegExp(r'^[а-яА-Я][а-яА-Я ]*$')
                                          .hasMatch(value)
                                  ? 'Введите корректное название'
                                  : null;
                            },
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Номер дома:",
                              style: TextStyle(
                                color: Constants.kPrimaryColor,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          InputWithIcon(
                            controller: _houseController,
                            icon: Icons.edit,
                            hint: "Номер дома",
                            validator: (value) {
                              return value.length > 20 ||
                                      value.length < 2 ||
                                      value == null
                                  ? 'Введите корректное название'
                                  : null;
                            },
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Статус питомца:",
                                  style: TextStyle(
                                    color: Constants.kPrimaryColor,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Row(
                                children: [
                                  petStatusWidget("Бездомный", PetStatus.adopt),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  petStatusWidget("Потерян", PetStatus.lost),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Описание:",
                              style: TextStyle(
                                color: Constants.kPrimaryColor,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          InputWithIcon(
                            controller: _descriptionController,
                            icon: Icons.edit,
                            hint: "Описание",
                            validator: (value) {
                              return value.length > 300 ||
                                      value.length < 10 ||
                                      !RegExp(r'^[а-яА-Я][а-яА-Я ,.:-]*$')
                                          .hasMatch(value)
                                  ? 'Введите корректное название'
                                  : null;
                            },
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 40,
                      ),
                      PrimaryButton(
                        buttonText: "Создать",
                        press: () async {
                          uploadPetAd();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget bottomSheet(Size screenSize) {
    return Container(
      height: screenSize.height * 0.14,
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 20,
      ),
      child: Column(
        children: [
          Text(
            "Выберите изображение",
            style: TextStyle(fontSize: 20.0, color: Constants.kPrimaryColor),
          ),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                icon: Icon(
                  Icons.camera,
                  color: Constants.kPrimaryColor,
                ),
                onPressed: () {
                  pickImage(ImageSource.camera);
                },
                label: Text(
                  "Камера",
                  style: TextStyle(color: Constants.kPrimaryColor),
                ),
              ),
              SizedBox(
                width: screenSize.width * 0.2,
              ),
              TextButton.icon(
                icon: Icon(
                  Icons.image,
                  color: Constants.kPrimaryColor,
                ),
                onPressed: () {
                  pickImage(ImageSource.gallery);
                },
                label: Text(
                  "Галерея",
                  style: TextStyle(color: Constants.kPrimaryColor),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget sexWidget(String text, Gender gender) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _selectedGender = gender;
          pickedGender = text;
        });
      },
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        side: BorderSide(
          color: (_selectedGender == gender)
              ? Constants.kPrimaryColor
              : Colors.grey,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: (_selectedGender == gender)
                ? Constants.kPrimaryColor
                : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget petStatusWidget(String text, PetStatus petStatus) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _petStatus = petStatus;
          _pickedPetSatus = text;
        });
      },
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        side: BorderSide(
          color:
              (_petStatus == petStatus) ? Constants.kPrimaryColor : Colors.grey,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: (_petStatus == petStatus)
                ? Constants.kPrimaryColor
                : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget categoryWidget() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Constants.kPrimaryColor, width: 2),
        borderRadius: BorderRadius.circular(50),
      ),
      child: DropdownButton(
        value: category,
        icon: Icon(
          Icons.arrow_drop_down,
          color: Constants.kPrimaryColor,
        ),
        hint: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            "Категория:",
            style: TextStyle(
              color: Constants.kPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        iconSize: 36,
        isExpanded: true,
        underline: SizedBox(),
        items: Constants.category.map((valueItem) {
          return DropdownMenuItem(
            value: valueItem,
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                valueItem,
                style: TextStyle(
                  color: Constants.kPrimaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            category = newValue;
          });
        },
      ),
    );
  }
}
