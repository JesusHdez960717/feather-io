import 'package:service/feather.dart';
import 'package:test/test.dart';

void main() {
  group('XmlElement - writing', () {
    test(
      'Should write the declaration, the namespace and indented children',
      () {
        final xml = S3Xml.root('ListBucketResult', [
          XmlElement.leaf('Name', 'photos'),
          XmlElement('Contents', elements: [XmlElement.leaf('Size', 12)]),
        ]).toXmlString();

        expect(
          xml,
          '<?xml version="1.0" encoding="UTF-8"?>\n'
          '<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">\n'
          '  <Name>photos</Name>\n'
          '  <Contents>\n'
          '    <Size>12</Size>\n'
          '  </Contents>\n'
          '</ListBucketResult>\n',
        );
      },
    );

    test('Should escape the text and the attributes', () {
      final xml = XmlElement(
        'Error',
        attributes: {'a': 'x"y'},
        elements: [XmlElement.leaf('Key', 'a&b<c>"d"')],
      ).toXmlString();

      expect(xml, contains('a="x&quot;y"'));
      expect(xml, contains('<Key>a&amp;b&lt;c&gt;&quot;d&quot;</Key>'));
    });

    test('Should tell an empty leaf from an element without content', () {
      expect(
        XmlElement.leaf('Prefix', null).toXmlString(),
        endsWith('<Prefix></Prefix>\n'),
      );
      expect(
        XmlElement('LocationConstraint').toXmlString(),
        endsWith('<LocationConstraint/>\n'),
      );
    });
  });

  group('XmlElement - reading', () {
    test(
      'Should read a DeleteObjects body with its declaration and namespace',
      () {
        final delete = DeleteObjectsRequest.fromXml(
          XmlElement.parse(
            '<?xml version="1.0" encoding="UTF-8"?>\n'
            '<Delete xmlns="http://s3.amazonaws.com/doc/2006-03-01/">'
            '<Quiet>true</Quiet>'
            '<Object><Key>a&amp;b.txt</Key></Object>'
            '<Object><Key>photos/</Key><VersionId>null</VersionId></Object>'
            '</Delete>',
          ),
        );

        expect(delete.keys, ['a&b.txt', 'photos/']);
        expect(delete.quiet, isTrue);
      },
    );

    test(
      'Should read prefixed names, CDATA, comments and numeric entities',
      () {
        final root = XmlElement.parse(
          '<s3:CompleteMultipartUpload xmlns:s3="ns"><!-- parts -->'
          '<s3:Part><s3:PartNumber> 1 </s3:PartNumber>'
          '<s3:ETag>&#34;abc&#x22;</s3:ETag></s3:Part>'
          '<s3:Part><s3:PartNumber>2</s3:PartNumber>'
          '<s3:ETag><![CDATA["d<e>f"]]></s3:ETag></s3:Part>'
          '</s3:CompleteMultipartUpload>',
        );
        final parts = CompleteMultipartRequest.fromXml(root).parts;

        expect(root.name, 'CompleteMultipartUpload');
        expect(parts.map((p) => p.partNumber), [1, 2]);
        expect(parts.map((p) => p.etag), ['"abc"', '"d<e>f"']);
      },
    );

    test('Should read attributes and self-closing elements', () {
      final root = XmlElement.parse("<A x='1' y=\"2\"><B/><C>t</C></A>");

      expect(root.attributes, {'x': '1', 'y': '2'});
      expect(root.child('B')?.elements, isEmpty);
      expect(root.childText('C'), 't');
      expect(root.child('D'), isNull);
    });

    test('Should reject a body that is not well-formed XML', () {
      for (final body in [
        '',
        'not xml',
        '<Delete>',
        '<Delete></Remove>',
        '<Delete><Object></Delete>',
        '<Delete a=1></Delete>',
        '<Delete></Delete><Other/>',
      ]) {
        expect(
          () => XmlElement.parse(body),
          throwsFormatException,
          reason: body,
        );
      }
    });

    test('Should reject a DeleteObjects body with another root or a part without number', () {
      expect(
        () => DeleteObjectsRequest.fromXml(XmlElement.parse('<Remove/>')),
        throwsFormatException,
      );
      expect(
        () => CompleteMultipartRequest.fromXml(
          XmlElement.parse('<C><Part><ETag>x</ETag></Part></C>'),
        ),
        throwsFormatException,
      );
    });
  });
}
