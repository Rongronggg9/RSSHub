"""Compatibility: Python 3.7+"""
from __future__ import annotations
from typing import NoReturn, Union

import re
import json
import urllib.request
from http.client import HTTPResponse
from argparse import ArgumentParser
from datetime import datetime
from pathlib import Path
from os import environ

API_ENDPOINT = 'https://registry.hub.docker.com/v2/repositories/{username}/{repository}/tags/?page_size=20'


def fetch_tags(username: str, repository: str) -> list[dict[Union[list[str], str]]]:
    """
    Fetch tags from the registry.
    """
    response: HTTPResponse
    with urllib.request.urlopen(API_ENDPOINT.format(username=username, repository=repository)) as response:
        body = response.read()
    return json.loads(body)['results']


def select_latest_tag(tags: list[dict[Union[list[str], str]]], pattern: str) -> str:
    """
    Select the latest tag that matches the pattern.
    """
    regex = re.compile(pattern)
    tags = sorted(tags, key=lambda t: datetime.strptime(t['tag_last_pushed'], '%Y-%m-%dT%H:%M:%S.%fZ'), reverse=True)
    latest_tag: str = next(tag['name'] for tag in tags if regex.match(tag['name']))
    print(f'Found latest tag: {latest_tag}')
    return latest_tag


def update_dockerfile(username: str, repository: str, pattern: str, path: str) -> bool:
    """
    Update the Dockerfile to use the latest tag.
    """
    tags = fetch_tags(username, repository)
    latest_tag = select_latest_tag(tags, pattern)
    new_image = f'FROM {username}/{repository}:{latest_tag}'
    try:
        with open(path, 'r') as f:
            old_image = f.read().strip()
    except FileNotFoundError:
        old_image = ''
    print(old_image, '>', new_image, sep=' ')
    if old_image != new_image:
        print(f'Updating "{path}"...', end='')
        with open(path, 'w') as f:
            f.write(f'{new_image}\n')
        print(' done!')
        return True
    print('No update.')
    return False


def main() -> NoReturn:
    """
    Script entry point.
    """
    parser = ArgumentParser(description='Update Dockerfile with the latest tag.', add_help=True)
    parser.add_argument('-u', '--username',
                        help='The username of the repository owner on Docker Hub.',
                        default=environ.get('USERNAME') or 'diygod')
    parser.add_argument('-r', '--repository',
                        help='The repository name.',
                        default=environ.get('REPOSITORY') or 'rsshub')
    parser.add_argument('-p', '--pattern',
                        help='The pattern to match the tag name.',
                        default=environ.get('PATTERN') or r'^chromium-bundled-\d{4}-\d{2}-\d{2}$')
    parser.add_argument('-d', '--dockerfile',
                        help='The path to the Dockerfile.',
                        default=environ.get('DOCKERFILE') or Path(__file__).parent.parent / 'Dockerfile')
    args = parser.parse_args()

    update_dockerfile(args.username, args.repository, args.pattern, args.dockerfile)


if __name__ == '__main__':
    main()
