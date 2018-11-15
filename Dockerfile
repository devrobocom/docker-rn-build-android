FROM openjdk:8-jdk


ENV SDK_HOME=/sdk \
  LANG=en_US.UTF-8 \
  LANGUAGE=en_US:en \
  LC_ALL=en_US.UTF-8

WORKDIR $SDK_HOME

RUN apt-get --quiet update --yes \
  && apt-get --quiet install --yes wget tar unzip lib32stdc++6 lib32z1 git file build-essential ca-certificates openssh-server --no-install-recommends \
  && apt-get -q autoremove \
  && apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

# configure JDK certs
RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure \
# configure ssh server
  && sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd \
  && mkdir -p /var/run/sshd

# Gradle
ENV GRADLE_VERSION 3.2.1
ENV GRADLE_SDK_URL https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip
RUN curl -sSL "${GRADLE_SDK_URL}" -o gradle-${GRADLE_VERSION}-bin.zip  \
  && unzip gradle-${GRADLE_VERSION}-bin.zip -d ${SDK_HOME}  \
  && rm -rf gradle-${GRADLE_VERSION}-bin.zip
ENV GRADLE_HOME ${SDK_HOME}/gradle-${GRADLE_VERSION}
ENV PATH ${GRADLE_HOME}/bin:$PATH

# android sdk|build-tools|image
ENV ANDROID_TARGET_SDK="android-27,android-28" \
  ANDROID_BUILD_TOOLS="build-tools-28.0.2,build-tools-28.0.3" \
  ANDROID_SDK_TOOLS="25.2.3" \
  ANDROID_HOME=${SDK_HOME}/android-sdk-linux \
  PATH=${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:$PATH:${ANDROID_HOME}/cmake/bin

RUN mkdir ${ANDROID_HOME} && wget --quiet --output-document=android-sdk.zip https://dl.google.com/android/repository/tools_r${ANDROID_SDK_TOOLS}-linux.zip \
  && unzip android-sdk.zip -d ${ANDROID_HOME}

# Android Cmake
RUN wget -q https://dl.google.com/android/repository/cmake-3.6.3155560-linux-x86_64.zip -O android-cmake.zip \
  && unzip -q android-cmake.zip -d ${ANDROID_HOME}/cmake \
  && chmod u+x ${ANDROID_HOME}/cmake/bin/ -R

# COPY package_file ${SDK_HOME}/

RUN echo y | android-sdk-linux/tools/android --silent update sdk --no-ui --all --filter "${ANDROID_TARGET_SDK}" \
  && echo y | android-sdk-linux/tools/android --silent update sdk --no-ui --all --filter platform-tools \
  && echo y | android-sdk-linux/tools/android --silent update sdk --no-ui --all --filter "${ANDROID_BUILD_TOOLS}" \
  && echo y | android-sdk-linux/tools/android --silent update sdk --no-ui --all --filter extra-android-m2repository \
  && echo y | android-sdk-linux/tools/android --silent update sdk --no-ui --all --filter extra-google-google_play_services \
  && echo y | android-sdk-linux/tools/android --silent update sdk --no-ui --all --filter extra-google-m2repository
  # && echo y | android-sdk-linux/tools/bin/sdkmanager --package_file=package_file

# Install all updates
RUN (while sleep 3; do echo "y"; done) | $ANDROID_HOME/tools/android update sdk -u

#####################
#  Install node.js  #
#####################


ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 10.x

RUN apt-get install curl -y && curl -sL "https://deb.nodesource.com/setup_${NODE_VERSION}" | bash -
RUN apt-get install -y nodejs
RUN curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
&& echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
&& apt-get update && apt-get install yarn


# Install global npm modules
RUN npm install -g react-native-cli
